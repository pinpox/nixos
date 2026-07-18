{ ... }:
{
  _class = "clan.service";
  manifest.name = "vikunja";
  manifest.description = "Vikunja to-do and task management";
  manifest.readme = "Self-hosted to-do app behind Authelia OIDC with a caddy reverse proxy";
  manifest.categories = [ "Office" ];
  manifest.exports.out = [
    "endpoints"
    "auth"
  ];

  roles.default = {
    description = "Sets up Vikunja with Authelia OIDC login and caddy reverse proxy";
    interface =
      { lib, meta, ... }:
      {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            default = "todos.${meta.domain}";
            description = "Host serving the Vikunja instance";
            example = "todos.example.com";
          };

          oidc = {
            issuer = lib.mkOption {
              type = lib.types.str;
              default = "https://id.pablo.tools";
              example = "https://auth.example.com";
              description = "Base URL (issuer) of the OIDC provider (Authelia)";
            };

            clientId = lib.mkOption {
              type = lib.types.str;
              default = "vikunja";
              description = "OIDC client ID registered with Authelia";
            };

            providerName = lib.mkOption {
              type = lib.types.str;
              default = "Pocket ID";
              description = "Display name shown on the Vikunja login button";
            };
          };
        };
      };

    perInstance =
      {
        settings,
        mkExports,
        ...
      }:
      {
        exports = mkExports {
          endpoints.hosts = [ settings.host ];
          auth.client = {
            clientId = settings.oidc.clientId;
            clientName = "Vikunja";
            # Vikunja derives its callback as <publicurl>auth/openid/<provider-id>.
            redirectUris = [ "https://${settings.host}/auth/openid/authelia" ];
            scopes = [
              "openid"
              "profile"
              "email"
            ];
            public = false;
          };
        };

        nixosModule =
          {
            config,
            pkgs,
            ...
          }:
          {
            # Reverse proxy; pki injects TLS for the .pin endpoint.
            services.caddy = {
              enable = true;
              virtualHosts."${settings.host}".extraConfig =
                "reverse_proxy 127.0.0.1:${toString config.services.vikunja.port}";
            };

            # OIDC client secret from the Pocket ID reconciler, via LoadCredential + *_FILE.
            systemd.services.vikunja = {
              after = [ "pocket-id-clients.service" ];
              requires = [ "pocket-id-clients.service" ];
              serviceConfig.LoadCredential = [
                "oidc-secret:/run/pocket-id-clients/${settings.oidc.clientId}/secret"
              ];
              environment.VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHELIA_CLIENTSECRET_FILE = "/run/credentials/vikunja.service/oidc-secret";
            };

            services.vikunja = {
              enable = true;
              port = 3456;
              frontendScheme = "https";
              frontendHostname = settings.host;

              settings = {
                service.timezone = "Europe/Berlin";
                files.basepath = "/var/lib/vikunja/files";

                defaultsettings = {
                  discoverable_by_name = true;
                  discoverable_by_email = true;
                  week_start = 1;
                };

                auth = {
                  # OIDC-only: no local login form.
                  local.enabled = false;
                  openid = {
                    enabled = true;
                    providers.authelia = {
                      name = settings.oidc.providerName;
                      authurl = settings.oidc.issuer;
                      clientid = settings.oidc.clientId;
                      scope = "openid profile email";
                    };
                  };
                };
              };
            };

            # Backup vikunja state (sqlite db + uploaded files).
            pinpox.services.restic-client.backup-paths-offsite = [ "/var/lib/vikunja" ];
          };
      };
  };
}
