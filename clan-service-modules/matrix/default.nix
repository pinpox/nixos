{ ... }:
# Self-hosted Matrix homeserver (Synapse) as a clan service. `server_name` is
# `serverName`; Synapse is served at `host` (Caddy + LE on the role machine).
# Discovery for `serverName` is delegated to `host` via /.well-known/matrix/*
# served on the apex (porree), not here. Federation rides 443 (no 8448/SRV).
{
  _class = "clan.service";
  manifest.name = "matrix";
  manifest.description = "Matrix Synapse homeserver with a declarative account reconciler";
  manifest.categories = [ "Social" ];

  roles.server = {
    description = "Runs Synapse + Postgres and reconciles declared accounts";

    interface =
      { lib, ... }:
      {
        options = {
          serverName = lib.mkOption {
            type = lib.types.str;
            default = "pinpox.com";
            description = "Matrix server_name (the domain in every @user:<serverName>). Permanent.";
          };
          host = lib.mkOption {
            type = lib.types.str;
            default = "matrix.pinpox.com";
            description = "Public FQDN where Synapse is served (Caddy + Let's Encrypt).";
          };
          users = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Bot account localparts to ensure exist (non-admin, generated password), idempotently.";
            example = [
              "opencrow_one"
              "opencrow_two"
            ];
          };
        };
      };

    perInstance =
      { settings, ... }:
      {
        nixosModule =
          {
            config,
            pkgs,
            lib,
            pinpox-utils,
            ...
          }:
          let
            regSecretFile =
              config.clan.core.vars.generators."matrix-registration-secret".files."registration_shared_secret.yaml".path;
          in
          {
            # Postgres needs C collation/ctype; create the role + DB explicitly on
            # first cluster init. Peer auth maps the matrix-synapse user → role.
            services.postgresql = {
              enable = true;
              initialScript = pkgs.writeText "matrix-synapse-init.sql" ''
                CREATE ROLE "matrix-synapse" WITH LOGIN;
                CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
                  TEMPLATE template0
                  LC_COLLATE = "C"
                  LC_CTYPE = "C";
              '';
            };

            # Registration shared secret + one generated password per declared user.
            clan.core.vars.generators = {
              "matrix-registration-secret" = {
                files."registration_shared_secret.yaml" = {
                  secret = true;
                  owner = "matrix-synapse";
                  mode = "0400";
                };
                runtimeInputs = with pkgs; [
                  coreutils
                  openssl
                ];
                script = ''
                  printf 'registration_shared_secret: "%s"\n' "$(openssl rand -hex 32)" \
                    > "$out/registration_shared_secret.yaml"
                '';
              };
            }
            // lib.listToAttrs (
              map (name: lib.nameValuePair "matrix-user-${name}" pinpox-utils.mkMatrixPassword) settings.users
            );

            systemd.services.matrix-synapse = {
              after = [ "postgresql.service" ];
              requires = [ "postgresql.service" ];
            };

            services.matrix-synapse = {
              enable = true;
              extraConfigFiles = [ regSecretFile ];
              settings = {
                server_name = settings.serverName;
                public_baseurl = "https://${settings.host}/";
                # Accounts are provisioned with the shared secret, never self-signup.
                # To federate only with matrix.org, set:
                # federation_domain_whitelist = [ "matrix.org" settings.serverName ];
                enable_registration = false;
                database = {
                  name = "psycopg2";
                  args = {
                    user = "matrix-synapse";
                    database = "matrix-synapse";
                  };
                };
                listeners = [
                  {
                    port = 8008;
                    bind_addresses = [ "127.0.0.1" ];
                    type = "http";
                    tls = false;
                    x_forwarded = true;
                    resources = [
                      {
                        names = [
                          "client"
                          "federation"
                        ];
                        compress = true;
                      }
                    ];
                  }
                ];
              };
            };

            # Idempotent: ensure each declared account exists once Synapse is up.
            systemd.services.matrix-user-reconcile = lib.mkIf (settings.users != [ ]) {
              description = "Ensure declared Matrix bot accounts exist";
              after = [ "matrix-synapse.service" ];
              wants = [ "matrix-synapse.service" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              path = [
                config.services.matrix-synapse.package
                pkgs.curl
              ];
              script = ''
                set -eu
                for _ in $(seq 1 60); do
                  curl -sf http://localhost:8008/_matrix/client/versions >/dev/null && break
                  sleep 2
                done
                ${lib.concatMapStringsSep "\n" (name: ''
                  register_new_matrix_user --exists-ok \
                    -c ${regSecretFile} \
                    -u ${lib.escapeShellArg name} \
                    --no-admin \
                    --password-file ${config.clan.core.vars.generators."matrix-user-${name}".files."password".path} \
                    http://localhost:8008
                '') settings.users}
              '';
            };

            # Public TLS endpoint; everything on `host` proxies to Synapse.
            services.caddy = {
              enable = true;
              virtualHosts."${settings.host}".extraConfig = ''
                reverse_proxy 127.0.0.1:8008
              '';
            };
          };
      };
  };
}
