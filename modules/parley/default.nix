{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.parley;

  httpListen = "127.0.0.1:9443";
  ircListen = "127.0.0.1:9667";
  dataDir = "/var/lib/parley";
  # Caddy obtains the cert for cfg.host; ghostunnel reads it straight from
  # Caddy's storage. The issuer is pinned to Let's Encrypt below so this path
  # is stable (Caddy's default would fall back to ZeroSSL's directory).
  caddyCertDir = "${config.services.caddy.dataDir}/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${cfg.host}";
  envFile = config.clan.core.vars.generators."parley".files."envfile".path;

  # parleyctl talks to the local API. Pre-set the endpoint and, when run as
  # root, the admin token so `sudo parleyctl accounts create ...` just works.
  parleyctl = pkgs.writeShellScriptBin "parleyctl" ''
    export PARLEY_ENDPOINT="''${PARLEY_ENDPOINT:-http://${httpListen}}"
    export PARLEY_DATA_DIR="''${PARLEY_DATA_DIR:-${dataDir}}"
    if [ -z "''${PARLEY_TOKEN:-}''${PARLEY_ADMIN_TOKEN:-}" ] && [ -r ${envFile} ]; then
      set -a
      . ${envFile}
      set +a
    fi
    exec ${cfg.package}/bin/parleyctl "$@"
  '';
in
{

  options.pinpox.services.parley = {
    enable = mkEnableOption "parley server";

    package = mkPackageOption pkgs "parley" { };

    domain = mkOption {
      type = types.str;
      default = "0cx.de";
      description = ''
        Identity domain of the instance: users are `nick@domain`. Other
        instances find this one through the DNS record
        `_parley._tcp.<domain> IN SRV 0 0 443 <host>`.
      '';
    };

    host = mkOption {
      type = types.str;
      default = "chat.${cfg.domain}";
      defaultText = literalExpression ''"chat.''${config.pinpox.services.parley.domain}"'';
      description = "Hostname serving the web UI, federation inbox and IRC over TLS.";
    };

    admins = mkOption {
      type = types.listOf types.str;
      default = [ "pinpox" ];
      description = ''
        Nicks that are admins regardless of their stored role or OIDC groups.
        The first SSO login with a matching `preferred_username` claims the
        nick (`auth.auto_link`).
      '';
    };

    oidc = {
      name = mkOption {
        type = types.str;
        default = "Pocket ID";
        description = "Label of the SSO login button.";
      };

      issuer = mkOption {
        type = types.str;
        default = "https://id.pablo.tools";
        description = "OIDC issuer.";
      };

      clientId = mkOption {
        type = types.str;
        default = "parley";
        description = ''
          Public (PKCE, no secret) client at the issuer, declared in the
          pocket-id `extraClients` in inventory.nix with redirect URI
          `https://<host>/auth/oidc/callback`.
        '';
      };

      adminGroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Provider groups whose members are admins. Applied on every login, so
          leaving a group demotes the account.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    # Authorises parleyctl and the admin API. With it set parleyd does not
    # print a /setup URL; the first admin is whoever signs in via SSO with a
    # nick in `admins`.
    clan.core.vars.generators."parley" = {
      files.envfile = { };
      runtimeInputs = [ pkgs.openssl ];
      script = ''
        echo "PARLEY_ADMIN_TOKEN=$(openssl rand -hex 32)" > $out/envfile
      '';
    };

    # OIDC only: `auth.local` merely hides the web password form, IRC would
    # still take a local password. So also strip every stored password; IRC
    # clients authenticate with tokens minted on /settings instead.
    systemd.services.parley-auth = {
      description = "Enforce OIDC-only login on Parley";
      after = [ "parley.service" ];
      requires = [ "parley.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [
        parleyctl
        pkgs.curl
        pkgs.coreutils
        pkgs.jq
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        for _ in $(seq 1 30); do
          curl -sf -o /dev/null http://${httpListen}/healthz && break
          sleep 1
        done
        parleyctl settings set auth.local false
        parleyctl -json accounts list \
          | jq -r '.[] | select(.has_password) | .nick' \
          | while read -r nick; do
              parleyctl accounts update "$nick" -clear-password >/dev/null
              echo "cleared password of $nick"
            done
      '';
    };

    environment.systemPackages = [ parleyctl ];

    systemd.services.parley = {
      description = "Parley federated IRC instance";
      documentation = [ "https://git.mills.io/prologic/parley" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        PARLEY_DOMAIN = cfg.domain;
        PARLEY_ENDPOINT = "https://${cfg.host}";
        PARLEY_HTTP_LISTEN = httpListen;
        PARLEY_IRC_LISTEN = ircListen;
        PARLEY_IRC_HOST = cfg.host;
        PARLEY_DATA_DIR = dataDir;
        PARLEY_ADMINS = concatStringsSep "," cfg.admins;
        PARLEY_OIDC_NAME = cfg.oidc.name;
        PARLEY_OIDC_ISSUER = cfg.oidc.issuer;
        PARLEY_OIDC_CLIENT_ID = cfg.oidc.clientId;
        # Caddy (X-Forwarded-For) and ghostunnel (PROXY v2) connect from
        # loopback; believe them so logs and limits see real clients.
        PARLEY_HTTP_PROXIES = "127.0.0.1/32";
        PARLEY_IRC_PROXIES = "127.0.0.1/32";
      }
      // optionalAttrs (cfg.oidc.adminGroups != [ ]) {
        PARLEY_OIDC_ADMIN_GROUPS = concatStringsSep "," cfg.oidc.adminGroups;
      };

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/parleyd";
        EnvironmentFile = envFile;
        DynamicUser = true;
        StateDirectory = "parley";
        StateDirectoryMode = "0700";
        Restart = "on-failure";
        RestartSec = "5s";
        TimeoutStopSec = "30s";

        # identity.key is the instance's private key.
        UMask = "0077";
        LimitNOFILE = 16384;

        # Hardening, following upstream's docs/parleyd.service
        NoNewPrivileges = true;
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        ProtectProc = "invisible";
        ProcSubset = "pid";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [ "@system-service" ];
        SystemCallErrorNumber = "EPERM";
      };
    };

    # parleyd's IRC listener is plaintext: terminate TLS in front of it and
    # pass the client address along via PROXY protocol v2. The cert/key are
    # loaded as systemd credentials by root, so Caddy's 0700 storage is fine.
    services.ghostunnel = {
      enable = true;
      servers.parley = {
        listen = "[::]:6697";
        target = ircListen;
        cert = "${caddyCertDir}/${cfg.host}.crt";
        key = "${caddyCertDir}/${cfg.host}.key";
        disableAuthentication = true;
        extraArguments = "--proxy-protocol";
      };
    };

    # Credentials are copied at start, so restart ghostunnel whenever Caddy
    # writes the cert (first issuance and renewals). Caddy stores the key
    # before the cert, so watching the cert sees a consistent pair.
    systemd.paths.parley-tls-cert = {
      wantedBy = [ "multi-user.target" ];
      pathConfig.PathChanged = "${caddyCertDir}/${cfg.host}.crt";
    };

    systemd.services.parley-tls-cert = {
      description = "Restart ghostunnel for Parley after Caddy renewed the cert";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.systemd}/bin/systemctl restart ghostunnel-server-parley.service";
      };
    };

    networking.firewall.allowedTCPPorts = [ 6697 ];

    # Web UI, well-known documents and federation inbox. Caddy also manages
    # the cert ghostunnel uses for IRC over TLS.
    services.caddy.virtualHosts."${cfg.host}".extraConfig = ''
      tls {
        issuer acme
      }
      reverse_proxy ${httpListen}
    '';
  };
}
