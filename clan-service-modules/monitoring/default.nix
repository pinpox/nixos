{ lib, ... }:
{
  _class = "clan.service";
  manifest.name = "monitoring";
  manifest.description = "Prometheus/Loki/Grafana monitoring stack";
  manifest.readme = ''
    	  Self-hosted monitoring with one role per component (prometheus, loki,
    	  grafana, blackbox, node-exporter, alertmanager-irc-relay)
    	  '';
  manifest.categories = [ "Monitoring" ];
  manifest.exports.out = [ "endpoints" "auth" ];

  roles.node-exporter = {
    description = "Prometheus node-exporter for host metrics (assign to every host you want scraped)";
    perInstance.nixosModule = ./node-exporter.nix;
  };

  roles.loki = {
    description = "Loki log aggregation server";
    perInstance.nixosModule = ./loki.nix;
  };

  roles.grafana = {
    description = "Grafana dashboard server";
    interface =
      { lib, meta, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            default = "status.${meta.domain}";
            example = "dashboards.example.com";
            description = "Domain for grafana";
          };

          oidc = {
            enable = lib.mkEnableOption "OIDC-only authentication (e.g. via Authelia). Disables the local login form.";

            issuer = lib.mkOption {
              type = lib.types.str;
              default = "";
              example = "https://auth.example.com";
              description = "Base URL of the OIDC provider (Authelia). Used to derive auth/token/userinfo endpoints.";
            };

            clientId = lib.mkOption {
              type = lib.types.str;
              default = "grafana";
              description = "OIDC client ID registered with the provider";
            };

            providerName = lib.mkOption {
              type = lib.types.str;
              default = "Authelia";
              description = "Display name shown on the Grafana login button";
            };
          };
        };
      };
    perInstance =
      {
        settings,
        roles,
        meta,
        mkExports,
        ...
      }:
      let


		  # TODO The generator shoudl be independeat of authelia or kanidm. Use a dependant one for authelia to create the hash
		  # TODO maybe we do not need a generato cofig at all, have a default?


        # Generator definition without runtimeInputs (pkgs isn't available
        # at inventory-eval time). Each nixosModule that declares this
        # generator adds runtimeInputs locally where pkgs IS available.
        oidcGenerator = lib.optionalAttrs settings.oidc.enable {
          share = true;
          files.client_secret = {
            owner = "grafana";
            group = "authelia-main";
            mode = "0440";
          };
          files.client_secret_hash.owner = "authelia-main";
          script = ''
            mkdir -p $out
            openssl rand -hex 32 > $out/client_secret
            authelia crypto hash generate argon2 --password "$(cat $out/client_secret)" \
              | sed 's/^Digest: //' > $out/client_secret_hash
          '';
        };
      in
      {
        exports = mkExports (
          { endpoints.hosts = [ settings.domain ]; }
          // lib.optionalAttrs settings.oidc.enable {
            auth.client = {
              clientId = settings.oidc.clientId;
              clientName = "Grafana";
              redirectUris = [ "https://${settings.domain}/login/generic_oauth" ];
              scopes = [
                "openid"
                "profile"
                "email"
                "groups"
              ];
              public = false;
            };
            auth.varsGenerator = oidcGenerator;
          }
        );
        nixosModule = import ./grafana.nix {
          inherit settings roles meta oidcGenerator;
        };
      };
  };

  roles.blackbox = {
    description = "Prometheus blackbox-exporter for HTTP/TLS probes";
    perInstance.nixosModule = ./blackbox.nix;
  };

  roles.alertmanager-irc-relay = {
    description = "Relay alertmanager notifications to an IRC channel";
    perInstance.nixosModule = ./alertmanager-irc-relay.nix;
  };

  roles.prometheus = {
    description = "Prometheus server (with bundled alertmanager). Discovers node-exporter and blackbox role members automatically.";
    interface =
      { lib, meta, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            default = "prometheus.${meta.domain}";
            example = "metrics.example.com";
            description = "Domain for the prometheus web UI (reverse proxied via caddy)";
          };
          blackboxTargets = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ "https://pablo.tools" ];
            example = [ "https://github.com" ];
            description = "Targets to monitor with the blackbox-exporter";
          };
          jsonTargets = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "http://birne.pin/restic-ahorn.json" ];
            description = "Targets to probe with the json-exporter";
          };
          webExternalUrl = lib.mkOption {
            type = lib.types.str;
            default = "https://vpn.prometheus.pablo.tools";
            description = "Prometheus web external URL";
          };
          alertmanagerWebExternalUrl = lib.mkOption {
            type = lib.types.str;
            default = "https://vpn.alerts.pablo.tools";
            description = "Alertmanager web external URL";
          };
        };
      };
    perInstance =
      {
        settings,
        roles,
        meta,
        mkExports,
        ...
      }:
      let
        # oauth2-proxy OIDC generator definition (without runtimeInputs —
        # added by each nixosModule where pkgs is available).
        # Produces: client_secret (raw), client_secret_hash (argon2 for
        # authelia), envfile (oauth2-proxy env with client+cookie secrets).
        prometheusOidcGenerator = {
          share = true;
          files.client_secret = {
            owner = "oauth2_proxy";
            group = "authelia-main";
            mode = "0440";
          };
          files.client_secret_hash.owner = "authelia-main";
          files.envfile = {
            owner = "oauth2_proxy";
            mode = "0400";
          };
          script = ''
            mkdir -p $out
            CLIENT_SECRET=$(openssl rand -hex 32)
            COOKIE_SECRET=$(openssl rand -hex 16)
            printf '%s' "$CLIENT_SECRET" > $out/client_secret
            authelia crypto hash generate argon2 --password "$CLIENT_SECRET" \
              | sed 's/^Digest: //' > $out/client_secret_hash
            printf 'OAUTH2_PROXY_CLIENT_SECRET=%s\nOAUTH2_PROXY_COOKIE_SECRET=%s\n' \
              "$CLIENT_SECRET" "$COOKIE_SECRET" > $out/envfile
          '';
        };
      in
      {
        exports = mkExports (
          { endpoints.hosts = [ settings.domain ]; }
          // {
            auth.client = {
              clientId = "prometheus";
              clientName = "Prometheus";
              redirectUris = [ "https://${settings.domain}/oauth2/callback" ];
              scopes = [
                "openid"
                "profile"
                "email"
                "groups"
              ];
              public = false;
            };
            auth.varsGenerator = prometheusOidcGenerator;
          }
        );
        nixosModule = import ./prometheus.nix {
          inherit settings roles meta prometheusOidcGenerator;
        };
      };
  };
}
