{
  config,
  pkgs,
  lib,
  ...
}:
with lib;

/*
  Setup cors on backblaze:
  https://github.com/ente-io/ente/discussions/1764

  # Get keys from backblaze
  export B2_APPLICATION_KEY_ID=
  export B2_APPLICATION_KEY=

  save to cors.json

  ```
  [
    {
      "corsRuleName": "entephotos",
      "allowedOrigins": [
        "*"
      ],
      "allowedHeaders": [
        "*"
      ],
      "allowedOperations": [
        "b2_download_file_by_id",
        "b2_download_file_by_name",
        "b2_upload_file",
        "b2_upload_part",
        "s3_get",
        "s3_post",
        "s3_put",
        "s3_head"
      ],
      "exposeHeaders": [
        "X-Amz-Request-Id",
        "X-Amz-Id-2",
        "ETag"
      ],
      "maxAgeSeconds": 3600
    }
  ]
  ```

  Apply using the backblaze-b2 cli tool:

  backblaze-b2 bucket update --cors-rules "$(<cors.json)" pinpox-ente allPrivate
*/

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
            default = "/credentials.yaml";
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

  config = mkIf (cfg.enable) (mkMerge [

    # (mkIf (cfg.webserver == "nginx") {
    #   services.nginx = {
    #     enable = true;
    #     # TODO
    #   };
    # })

    (mkIf (cfg.webserver == "caddy") {
      services.caddy = {
        enable = true;
        virtualHosts = {

          "${cfg.web-host}".extraConfig =
            let
              ente-web = pkgs.ente-web.override {

                # See for options: https://github.com/ente-io/ente/blob/main/web/apps/photos/.env
                extraBuildEnv = {
                  NEXT_PUBLIC_ENTE_ENDPOINT = cfg.api-host;
                  NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT = cfg.albums-host;
                  # NEXT_PUBLIC_ENTE_ACCOUNTS_URL = http://localhost:3001
                  # NEXT_PUBLIC_ENTE_FAMILY_URL = http://localhost:3001
                  # NEXT_PUBLIC_ENTE_PAYMENTS_URL = http://localhost:3001
                  # TODO: this should only be set if the album-host is not null
                };
              };
            in
            ''
              header Access-Control-Allow-Origin "*"
              root * ${ente-web}
              file_server
              encode zstd gzip
            '';

          "${cfg.albums-host}".extraConfig =
            let
              ente-web = pkgs.ente-web.override {
                # See for options: https://github.com/ente-io/ente/blob/main/web/apps/photos/.env
                extraBuildEnv = {
                  NEXT_PUBLIC_ENTE_ENDPOINT = cfg.api-host;
                  NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT = cfg.albums-host;
                  # NEXT_PUBLIC_ENTE_ACCOUNTS_URL = http://localhost:3001
                  # NEXT_PUBLIC_ENTE_PAYMENTS_URL = http://localhost:3001
                  # NEXT_PUBLIC_ENTE_FAMILY_URL = http://localhost:3001
                };
              };
            in
            ''
              header Access-Control-Allow-Origin "*"
              root * ${ente-web}
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

      clan.core.vars.generators."ente" = {
        files.credentials-yaml = {
          owner = "ente";
          group = "ente";
        };

        # files.<name>.secret = true;
        script = "cp $prompts/credentials $out/credentials-yaml";
        # }

        prompts.credentials.type = "multiline";
        prompts.credentials.persist = true;
      };

      # Service
      systemd.services.ente = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        description = "ente";

        serviceConfig = {

          WorkingDirectory = "/var/lib/ente";
          BindReadOnlyPaths = [
            "${config.clan.core.vars.generators."ente".files."credentials-yaml".path}:/credentials.yaml"
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
