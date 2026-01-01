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

  # The user generation script
  authelia-users-gen = "${./authelia-users-gen.py}";
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

  };

  config = mkIf cfg.enable (
    let
      # Generate config JSON from declarative users, filtering out null values
      configJson = pkgs.writeText "authelia-users-config.json" (
        builtins.toJSON {
          users = lib.mapAttrs (
            _name: user: lib.filterAttrs (_: v: v != null && v != [ ]) user
          ) cfg.declarativeUsers.users;
        }
      );

      # Script to generate users file (runs as root via + prefix)
      usersGenScript = pkgs.writeShellScript "authelia-users-gen" ''
        ${pkgs.python3}/bin/python3 ${authelia-users-gen} ${configJson} /run/authelia-main/users.yaml
        chown authelia-main:authelia-main /run/authelia-main/users.yaml
      '';
    in
    {

      systemd.services.authelia-main = {
        serviceConfig.LoadCredential = [
          "jwt-secret:${config.clan.core.vars.generators.authelia.files.jwt-secret.path}"
          "session-secret:${config.clan.core.vars.generators.authelia.files.session-secret.path}"
          "storage-encryption-key:${config.clan.core.vars.generators.authelia.files.storage-encryption-key.path}"
        ];

        # Run as root (+) to read secrets, then chown to authelia
        serviceConfig.ExecStartPre = [ "+${usersGenScript}" ];
        serviceConfig.RuntimeDirectory = lib.mkDefault "authelia-main";

      };

      services.authelia.instances.main = {
        enable = true;

        secrets = {
          jwtSecretFile = "/run/credentials/authelia-main.service/jwt-secret";
          sessionSecretFile = "/run/credentials/authelia-main.service/session-secret";
          storageEncryptionKeyFile = "/run/credentials/authelia-main.service/storage-encryption-key";
        };

        # Enable templating in cnfig files
        # environmentVariables = {
        #   X_AUTHELIA_CONFIG_FILTERS = "template";
        # };

        settings = {
          theme = "dark";

          server.address = "tcp://127.0.0.1:${toString port}";

          log = {
            level = "info";
            format = "text";
          };

          authentication_backend = {
            file.path = "/run/authelia-main/users.yaml";
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
        files.jwt-secret = { };
        files.session-secret = { };
        files.storage-encryption-key = { };

        runtimeInputs = with pkgs; [
          coreutils
          openssl
        ];

        script = ''
          mkdir -p $out
          openssl rand -hex 64 > $out/jwt-secret
          openssl rand -hex 64 > $out/session-secret
          openssl rand -hex 64 > $out/storage-encryption-key
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
