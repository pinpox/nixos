let
  users = {
    lislon = {
      email = "lislon@pablo.tools";
      groups = [ "users" ];
    };
    pinpox = {
      email = "mail@pablo.tools";
      groups = [
        "admins"
        "users"
      ];
    };
  };
in

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

  # Custom authelia package from pinpox fork with user yaml filters support
  authelia-custom = pkgs.authelia.override {
    buildGoModule =
      args:
      pkgs.buildGoModule (
        args
        // {
          src = pkgs.fetchFromGitHub {
            owner = "pinpox";
            repo = "authelia";
            rev = "user-yaml-filters";
            hash = "sha256-0gormVGxtfL3Ia0yljwRafsvjVg2rDrgMWoni2cC5QA=";
          };
          vendorHash = "sha256-dBiUbvZjGbmJqwUBcUKyY/CIdngmvyUAY5aeiEv7OCI=";
        }
      );
  };

  # Generate usersConfig from the users attrset
  yamlFormat = pkgs.formats.yaml { };

  usersConfig = {
    users = lib.mapAttrs (name: user: {
      displayname = name;
      password = ''{{ secret "/run/credentials/authelia-main.service/${name}-password-hash" }}'';
      email = user.email;
      groups = user.groups;
    }) users;
  };

  usersFile = yamlFormat.generate "authelia-users.yaml" usersConfig;

  # Generate LoadCredential entries for user password hashes
  userCredentials = lib.mapAttrsToList (
    name: _:
    "${name}-password-hash:${
      config.clan.core.vars.generators."authelia-user-${name}".files.password-hash.path
    }"
  ) users;

  # Generate vars generators for each user
  userGenerators = lib.mapAttrs' (
    name: _:
    lib.nameValuePair "authelia-user-${name}" {
      files.password = { };
      files.password-hash = { };

      runtimeInputs = with pkgs; [
        coreutils
        authelia
        xkcdpass
        gnused
      ];

      script = ''
        mkdir -p $out
        xkcdpass -n 7 -d- > $out/password
        authelia crypto hash generate argon2 --password "$(cat $out/password)" | sed 's/^Digest: //' > $out/password-hash
      '';
    }
  ) users;
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
  };

  config = mkIf cfg.enable {

    systemd.services.authelia-main = {
      serviceConfig.LoadCredential = [
        "jwt-secret:${config.clan.core.vars.generators.authelia.files.jwt-secret.path}"
        "session-secret:${config.clan.core.vars.generators.authelia.files.session-secret.path}"
        "storage-encryption-key:${config.clan.core.vars.generators.authelia.files.storage-encryption-key.path}"
      ]
      ++ userCredentials;
    };

    services.authelia.instances.main = {
      enable = true;
      package = authelia-custom;

      secrets = {
        jwtSecretFile = "/run/credentials/authelia-main.service/jwt-secret";
        sessionSecretFile = "/run/credentials/authelia-main.service/session-secret";
        storageEncryptionKeyFile = "/run/credentials/authelia-main.service/storage-encryption-key";
      };

      # Enable templating in cnfig files
      environmentVariables = {
        X_AUTHELIA_CONFIG_FILTERS = "template";
      };

      settings = {
        theme = "dark";

        server.address = "tcp://127.0.0.1:${toString port}";

        log = {
          level = "info";
          format = "text";
        };

        authentication_backend.file.path = usersFile;

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

    clan.core.vars.generators = {
      authelia = {
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
    }
    // userGenerators;

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
  };
}
