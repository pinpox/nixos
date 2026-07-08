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
              default = "https://auth.pablo.tools";
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
              default = "Authelia";
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
      let
        # Base OIDC secret generator. Kept pkgs-free so it can be exported and
        # consumed at inventory-eval time. runtimeInputs (which need pkgs) are
        # added by each host that declares it — see the nixosModule below and
        # Authelia's own declaration driven by the auth.varsGenerator export.
        #   client_secret_hash → argon2 hash for Authelia's client_secret_file
        #   envfile            → VIKUNJA_AUTH_OPENID_..._CLIENTSECRET for vikunja
        oidcGenerator = {
          share = true;
          files.client_secret_hash = { };
          files.envfile.mode = "0400";
          script = ''
            mkdir -p $out
            SECRET="$(openssl rand -hex 32)"
            authelia crypto hash generate argon2 --password "$SECRET" \
              | sed 's/^Digest: //' > $out/client_secret_hash
            printf 'VIKUNJA_AUTH_OPENID_PROVIDERS_AUTHELIA_CLIENTSECRET=%s\n' "$SECRET" \
              > $out/envfile
          '';
        };
      in
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
          # Authelia declares this generator on its own host (share = true), so
          # vikunja need not be co-located with Authelia. Both sides read the
          # secret as root (Authelia via LoadCredential, vikunja via systemd
          # EnvironmentFile), so no file owner is required.
          auth.varsGenerator = oidcGenerator;
        };

        nixosModule =
          {
            config,
            pkgs,
            ...
          }:
          let
            gen = config.clan.core.vars.generators."authelia-oidc-${settings.oidc.clientId}";
          in
          {
            # Declared on the vikunja host too (share = true), so this host
            # receives the envfile regardless of where Authelia runs.
            # runtimeInputs are added here because pkgs is only in scope inside
            # the nixosModule.
            clan.core.vars.generators."authelia-oidc-${settings.oidc.clientId}" = oidcGenerator // {
              runtimeInputs = with pkgs; [
                coreutils
                openssl
                authelia
                gnused
              ];
            };

            # Reverse proxy. TLS for the .pin endpoint is injected by the pki
            # clan service automatically.
            services.caddy = {
              enable = true;
              virtualHosts."${settings.host}".extraConfig =
                "reverse_proxy 127.0.0.1:${toString config.services.vikunja.port}";
            };

            services.vikunja = {
              enable = true;
              port = 3456;
              frontendScheme = "https";
              frontendHostname = settings.host;
              environmentFiles = [ gen.files.envfile.path ];

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
