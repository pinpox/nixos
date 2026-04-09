{ settings, roles, meta, prometheusOidcGenerator }:
{
  lib,
  pkgs,
  config,
  flake-self,
  pinpox-utils,
  ...
}:
let
  nodeExporterHosts = builtins.attrNames (roles."node-exporter".machines or { });
in
{
  clan.core.vars.generators."restic-exporter" = pinpox-utils.mkEnvGenerator [
    "RESTIC_PASSWORD"
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "RESTIC_REPOSITORY"
  ];

  # OIDC client secret generator — declared here so the producing host has the
  # files. The same definition is exported via auth.varsGenerator so the
  # authelia host also declares it (share=true). runtimeInputs added here
  # because pkgs isn't available at inventory-eval time.
  clan.core.vars.generators."authelia-oidc-prometheus" = prometheusOidcGenerator // {
    runtimeInputs = with pkgs; [
      coreutils
      openssl
      authelia
      gnused
    ];
  };

  # oauth2-proxy sits between Caddy and Prometheus and handles the OIDC
  # client flow against Authelia. Prometheus itself stays on 127.0.0.1:9090
  # (loopback only); the only way to reach it is through oauth2-proxy on
  # 127.0.0.1:4180, which Caddy reverse-proxies as ${settings.domain}.
  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    clientID = "prometheus";
    keyFile = config.clan.core.vars.generators."authelia-oidc-prometheus".files.envfile.path;
    oidcIssuerUrl = "https://auth.pablo.tools";
    redirectURL = "https://${settings.domain}/oauth2/callback";
    upstream = [ "http://127.0.0.1:9090" ];
    httpAddress = "http://127.0.0.1:4180";
    cookie.secure = true;
    cookie.refresh = "1h";
    email.domains = [ "*" ];
    setXauthrequest = true;
    reverseProxy = true;
    extraConfig = {
      skip-provider-button = true;
      # Authelia's prometheus client is registered with require_pkce = true,
      # so oauth2-proxy must send a PKCE code_challenge on the authorize
      # request and the matching verifier on the token exchange.
      code-challenge-method = "S256";
      # Authelia's authorization_policies already restrict who can reach this
      # client; oauth2-proxy doesn't need to enforce its own allowlist.
    };
  };

  # Reverse proxy for the prometheus web UI. The pki clan service auto-issues
  # a TLS cert for ${settings.domain} and prepends a `tls` directive to this
  # vhost; dm-dns distributes a CNAME so any clan-internal host can resolve
  # it. Caddy hands traffic to oauth2-proxy, which performs the OIDC dance
  # against Authelia and (if authorized) proxies upstream to Prometheus.
  services.caddy = {
    enable = true;
    virtualHosts."${settings.domain}".extraConfig = "reverse_proxy 127.0.0.1:4180";
  };

  services.prometheus = {
    enable = true;

    # Bind to localhost only — defense in depth on top of the host firewall.
    # The only way in from outside the host is via Caddy → oauth2-proxy →
    # 127.0.0.1:9090.
    listenAddress = "127.0.0.1";

    # Disable config checks. They will fail because they run sandboxed and
    # can't access external files, e.g. the secrets stored in /run/keys
    # https://github.com/NixOS/nixpkgs/blob/d89d7af1ba23bd8a5341d00bdd862e8e9a808f56/nixos/modules/services/monitoring/prometheus/default.nix#L1732-L1738
    checkConfig = false;

    webExternalUrl = settings.webExternalUrl;
    extraFlags = [
      "--log.level=debug"
      "--storage.tsdb.retention.size='6GB'"
    ];
    ruleFiles = [
      (pkgs.writeText "prometheus-rules.yml" (
        builtins.toJSON {
          groups = [
            {
              name = "alerting-rules";
              rules = import ./alert-rules.nix { inherit lib meta; };
            }
          ];
        }
      ))
    ];
    alertmanagers = [ { static_configs = [ { targets = [ "localhost:9093" ]; } ]; } ];

    scrapeConfigs = [
      {
        job_name = "backup-reports";
        scrape_interval = "60m";
        metrics_path = "/probe";
        static_configs = [ { targets = settings.jsonTargets; } ];

        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:7979"; # The blackbox exporter's real hostname:port.
          }
        ];
      }
      # TODO: move restic-client to a clan service so this can be discovered
      # via roles.<restic>.machines instead of filtering flake-self.
      {
        job_name = "restic-exporter";
        scrape_interval = "1h";
        metrics_path = "/probe";
        static_configs = [
          {
            targets = (
              builtins.attrNames (
                lib.filterAttrs (
                  n: v: v.config.pinpox.services.restic-client.enable
                ) flake-self.nixosConfigurations
              )
            );
          }
        ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:${builtins.toString config.services.restic-exporter.port}";
          }
        ];
      }
      {
        job_name = "blackbox";
        scrape_interval = "2m";
        metrics_path = "/probe";
        params = {
          module = [ "http_2xx" ];
        };
        static_configs = [ { targets = settings.blackboxTargets; } ];

        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:9115"; # The blackbox exporter's real hostname:port.
          }
        ];
      }
      {
        job_name = "node-stats";
        static_configs = [
          {
            # Hosts assigned the "node-exporter" role of this monitoring instance
            targets = map (h: "${h}.${meta.domain}:9100") nodeExporterHosts;
          }
        ];
      }
    ];
    alertmanager = {
      enable = true;
      # port = 9093; # Default
      listenAddress = "127.0.0.1";
      webExternalUrl = settings.alertmanagerWebExternalUrl;
      environmentFile = /var/src/secrets/alertmanager/envfile;
      configuration = {

        route = {
          receiver = "all";
          group_by = [ "instance" ];
          group_wait = "30s";
          group_interval = "2m";
          repeat_interval = "24h";
        };

        receivers = [
          {
            name = "all";
            webhook_configs = [
              { url = "http://127.0.0.1:11000/alert"; } # matrix-hook
              { url = with config.services.alertmanager-ntfy; "http://${httpAddress}:${httpPort}"; } # alertmanger-ntfy
            ];
          }
        ];
      };
    };
  };
}
