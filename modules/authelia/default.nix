{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.authelia;
  port = 9091;

  # Generic script to transform Nix JSON with *File references
  nix-to-config = ./nix-to-config.py;
in
{

  options.pinpox.services.authelia = {
    enable = mkEnableOption "authelia authentication server";

    host = mkOption {
      type = types.str;
      default = "auth.pablo.tools";
      description = "Host serving authelia";
      example = "login.pablo.tools";
    };

    declarativeUsers = {
      enable = lib.mkEnableOption "declarative users";
      users = lib.mkOption {
        type = lib.types.attrsOf lib.types.attrs;
        default = { };
        description = ''
          Authelia users as JSON-compatible attribute sets.
          For any field, use a *File suffix (e.g. passwordFile) to read
          the value from a file at runtime, keeping secrets out of the Nix store.
        '';
        example = lib.literalExpression ''
          {
            pinpox = {
              displayname = "Pablo";
              email = "mail@example.com";
              groups = [ "admins" "users" ];
              passwordFile = "/run/secrets/pinpox-hash";
            };
          }
        '';
      };
    };

    oidcClients = lib.mkOption {
      type = lib.types.listOf lib.types.attrs;
      default = [ ];
      description = ''
        OIDC clients for Authelia. Each client needs at minimum:
        - client_id
        - client_secret (hashed) or client_secret_file (path to file with plaintext secret)
        - redirect_uris
      '';
      example = lib.literalExpression ''
        [
          {
            client_id = "miniflux";
            client_secret_file = "/run/secrets/miniflux-oidc-secret";
            redirect_uris = [ "https://news.example.com/oauth2/oidc/callback" ];
            scopes = [ "openid" "profile" "email" ];
            authorization_policy = "two_factor";
          }
        ]
      '';
    };

  };

  config = mkIf cfg.enable (
    let
      # Generate users config JSON (with *File references to be resolved at runtime)
      usersConfigJson = pkgs.writeText "authelia-users-input.json" (
        builtins.toJSON {
          users = lib.mapAttrs (
            _name: user: lib.filterAttrs (_: v: v != null && v != [ ]) user
          ) cfg.declarativeUsers.users;
        }
      );

      # Generate OIDC clients config JSON (with *File references)
      oidcConfigJson = pkgs.writeText "authelia-oidc-input.json" (
        builtins.toJSON {
          identity_providers.oidc.clients = cfg.oidcClients;
        }
      );
    in
    {

      systemd.services.authelia-main = {
        # mkBefore so files exist before authelia's preStart validates config
        preStart = lib.mkBefore ''
          ${pkgs.python3}/bin/python3 ${nix-to-config} ${usersConfigJson} /run/authelia-main/users.json
          ${lib.optionalString (cfg.oidcClients != []) ''
            ${pkgs.python3}/bin/python3 ${nix-to-config} ${oidcConfigJson} /run/authelia-main/oidc.json
          ''}
        '';
        serviceConfig.RuntimeDirectory = lib.mkDefault "authelia-main";
      };

      services.authelia.instances.main = {
        enable = true;

        secrets = with config.clan.core.vars.generators.authelia.files; {
          jwtSecretFile = jwt-secret.path;
          sessionSecretFile = session-secret.path;
          storageEncryptionKeyFile = storage-encryption-key.path;
        } // lib.optionalAttrs (cfg.oidcClients != []) {
          oidcHmacSecretFile = oidc-hmac-secret.path;
          oidcIssuerPrivateKeyFile = oidc-jwks-key.path;
        };

        # Include generated OIDC config at runtime
        settingsFiles = lib.mkIf (cfg.oidcClients != []) [
          "/run/authelia-main/oidc.json"
        ];

        settings = {
          theme = "dark";

          server.address = "tcp://127.0.0.1:${toString port}";

          log = {
            level = "info";
            format = "text";
          };

          authentication_backend = {
            file.path = "/run/authelia-main/users.json";
            # Disable password reset/change when using declarative users,
            # since changes would be overwritten on service restart
            password_reset.disable = cfg.declarativeUsers.enable;
            password_change.disable = cfg.declarativeUsers.enable;
          };

          access_control = {
            default_policy = "deny";
            rules = [
              {
                domain = "*.pablo.tools";
                policy = "one_factor";
              }
            ];
          };

          session = {
            name = "authelia_session";
            cookies = [
              {
                domain = "pablo.tools";
                authelia_url = "https://${cfg.host}";
              }
            ];
          };

          storage.local.path = "/var/lib/authelia-main/db.sqlite3";

          notifier = {
            filesystem = {
              filename = "/var/lib/authelia-main/notifications.txt";
            };
          };
        };
      };

      clan.core.vars.generators.authelia = {
        files.jwt-secret.owner = "authelia-main";
        files.session-secret.owner = "authelia-main";
        files.storage-encryption-key.owner = "authelia-main";
        files.oidc-hmac-secret.owner = "authelia-main";
        files.oidc-jwks-key.owner = "authelia-main";

        runtimeInputs = with pkgs; [
          coreutils
          openssl
        ];

        script = ''
          mkdir -p $out
          openssl rand -hex 64 > $out/jwt-secret
          openssl rand -hex 64 > $out/session-secret
          openssl rand -hex 64 > $out/storage-encryption-key
          openssl rand -hex 64 > $out/oidc-hmac-secret
          openssl genrsa -out $out/oidc-jwks-key 4096
        '';
      };

      # Backup authelia data
      pinpox.services.restic-client.backup-paths-offsite = [
        "/var/lib/authelia-main"
      ];

      # Reverse proxy via caddy (caddy handles ACME internally)
      services.caddy = {
        enable = true;
        virtualHosts."${cfg.host}".extraConfig = ''
          reverse_proxy http://127.0.0.1:${toString port}
        '';
      };
    }
  );
}
