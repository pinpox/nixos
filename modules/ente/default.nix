{
  config,
  pkgs,
  lib,
  ...
}:
with lib;

let
  cfg = config.services.ente;
  format = pkgs.formats.yaml { };
  configFile = format.generate "local.yaml" cfg.settings;
in
{

  options.services.ente = rec {
    enable = mkEnableOption "ente service";

    web = mkOption {
      default = enable;
      description = "Whether to enable the web frontend";
      example = false;
      type = with types; bool;
    };

    albums = mkOption {
      default = web;
      description = "Whether to enable public albums to allow sharing";
      example = false;
      type = with types; bool;
    };

    web-host = mkOption {
      type = types.str;
      # default = "photos.0cx.de";
      description = ''
        TODO
      '';
    };

    albums-host = mkOption {
      type = types.str;
      # default = "albums.0cx.de";
      description = ''
        TODO
      '';
    };

    api-host = mkOption {
      type = types.str;
      # default = "albums.0cx.de";
      description = ''
        TODO
      '';
    };

    webserver = mkOption {
      type = types.enum [
        "nginx"
        "caddy"
      ];
      # default = "caddy";
      default = "nginx";
      description = ''
        Whether to use nginx or caddy for virtual host management.

        Further nginx configuration can be done by adapting `services.nginx.virtualHosts.<name>`.
        See [](#opt-services.nginx.virtualHosts) for further information.

        Further caddy configuration can be done by adapting `services.caddy.virtualHosts.<name>`.
        See [](#opt-services.caddy.virtualHosts) for further information.
      '';
    };

    credentialsFile = mkOption {
      default = null;
      description = # yaml
        ''
          # TODO
          # https://github.com/ente-io/ente/blob/main/server/scripts/compose/credentials.yaml#L10

          jwt:
              secret: "00000000000000000000000000000000000000000000"
          key:
              encryption: 00000000000000000000000000000000000000000000
              hash: 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
          s3:
              b2-eu-cen:
                  key: "0000000000000000000000000"
                  secret: "0000000000000000000000000000000"
                  endpoint: "000000000000000000000000000000"
                  region: "00000000000"
                  bucket: "00000000000"
        '';
      example = "/run/secrets/ente";
      type = with types; nullOr path;
    };

    environmentFile = mkOption {
      default = null;
      description = ''
        Environment file (see {manpage}`systemd.exec(5)` "EnvironmentFile="
        section for the syntax) passed to the service. This option can be
        used to safely include secrets in the configuration.
      '';
      example = "/run/secrets/ente";
      type = with types; nullOr path;
    };

    settings = lib.mkOption {
      default = { };
      description = ''
        ente configuration as a Nix attribute set. All settings can also be passed
        from the environment.

        See https://github.com/ente-io/ente/blob/main/server/configurations/local.yaml for possible options.
      '';
      type = lib.types.submodule {
        freeformType = format.type;
        options = {

          credentials-file = lib.mkOption {
            type = lib.types.str;
            default = "${cfg.credentialsFile}";
            internal = true;
          };

          apps.public-albums = lib.mkOption {
            type = with types; str;
            default = "https://albums.ente.io";
            description = ''
              Specify the base endpoints for various apps
              If you're running a self hosted instance and wish to serve public links,
              set this to the URL where your albums web app is running.
            '';
          };

          s3 = {
            b2-eu-cen = {
              endpoint = lib.mkOption {
                type = with types; str;
                default = "";
                description = ''
                  TODO
                '';
              };
              region = lib.mkOption {
                type = with types; str;
                default = "";
                description = ''
                  TODO
                '';
              };
              bucket = lib.mkOption {
                type = with types; str;
                default = "";
                description = ''
                  TODO
                '';
              };
            };
          };

          # Key used for encrypting customer emails before storing them in DB

          webauthn = {
            rpid = lib.mkOption {
              type = lib.types.str;
              default = "localhost";
              description = ''
                Our "Relying Party" ID. This scopes the generated credentials.
                See: https://www.w3.org/TR/webauthn-3/#rp-id
              '';
            };

            rporigins = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ "http://localhost:3001" ];
              description = ''
                Whitelist of origins from where we will accept WebAuthn requests.
                See: https://github.com/go-webauthn/webauthn
              '';
            };
          };

          db = {
            host = lib.mkOption {
              type = lib.types.str;
              default = "/run/postgresql";
              description = "Database host";
            };

            port = lib.mkOption {
              type = lib.types.str;
              default = "5432";
              description = "Database port";
            };

            sslmode = lib.mkOption {
              type = types.enum [
                "enable"
                "disable"
              ];
              default = "disable";
              description = "whether to enable SSL for the DB connection";
            };

            user = lib.mkOption {
              type = lib.types.str;
              default = "ente";
              description = "Database username";
            };
          };
        };
      };
    };
  };

  config =
    let
      web-package = pkgs.ente-web.overrideAttrs {

        # See for options: https://github.com/ente-io/ente/blob/main/web/apps/photos/.env
        extraBuildEnv = {

          # The Ente API endpoint
          NEXT_PUBLIC_ENTE_ENDPOINT = cfg.api-host;

          # The URL of the accounts app
          # NEXT_PUBLIC_ENTE_ACCOUNTS_URL = http://localhost:3001

          # The URL of the payments app
          # NEXT_PUBLIC_ENTE_PAYMENTS_URL = http://localhost:3001

          # The URL for the shared albums deployment
          # Note: To use your custom albums endpoint in the generated public link, set the
          # `apps.public-albums` property in museum's configuration.
          NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT = cfg.album-host; # TODO: this should only be set if the album-host is not null

          # The URL of the family plans web app
          # NEXT_PUBLIC_ENTE_FAMILY_URL = http://localhost:3001

        };
      };
    in
    mkIf (cfg.enable) (mkMerge [

      (mkIf (cfg.webserver == "nginx") {
        services.nginx = {
          enable = true;
          # TODO
        };
      })

      (mkIf (cfg.webserver == "caddy") {
        services.caddy = {
          enable = true;
          virtualHosts = {

            "${cfg.web-host}".extraConfig = ''
              root * ${web-package}
              file_server
              encode zstd gzip
            '';

            "${cfg.albums-host}".extraConfig = ''
              root * ${web-package}
              file_server
              encode zstd gzip
            '';
          };
        };
      })
      {

        services.postgresql = {
          enable = true;
          package = pkgs.postgresql_15;
          ensureUsers = [
            {
              name = cfg.settings.db.user;
              ensureDBOwnership = true;
            }
          ];
          ensureDatabases = [ cfg.settings.db.user ];
        };

        # User and group
        users.users.ente = {
          isSystemUser = true;
          description = "ente user";
          extraGroups = [ "ente" ];
          group = "ente";
        };

        users.groups.ente.name = "ente";

        # Service
        systemd.services.ente = {
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          description = "ente";

          serviceConfig = {

            WorkingDirectory = "/var/lib/ente";
            BindReadOnlyPaths = [
              "${cfg.credentialsFile}:/var/lib/ente/crendentials.yaml"
              "${configFile}:/var/lib/ente/configurations/local.yaml"
              "${pkgs.museum}/share/museum/migrations:/var/lib/ente/migrations"
              "${pkgs.museum}/share/museum/mail-templates:/var/lib/ente/mail-templates"
            ];

            BindPaths = "/run/postgresql";

            EnvironmentFile = [ cfg.environmentFile ];

            User = "ente";
            ExecStart = "${lib.getExe pkgs.museum}";
            Restart = "on-failure";
            RestartSec = "5s";
          };
        };
      }
    ]);
}
