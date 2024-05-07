{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.services.dex;
in
{

  options.pinpox.services.dex = {
    enable = mkEnableOption "dex authorization provider";
    host = mkOption {
      type = types.str;
      default = "login.0cx.de";
      description = "Host serving dex";
      example = "login.0cx.de";
    };
  };

  config = mkIf cfg.enable {

    # Reverse proxy
    services.caddy.virtualHosts."${cfg.host
    }".extraConfig = "reverse_proxy ${config.services.dex.settings.web.http}";

    # Secrets
    lollypops.secrets.files."dex/envfile" = { };

    # Backups
    pinpox.services.restic-client.backup-paths-offsite = [
      config.services.dex.settings.storage.config.file
      "/var/lib/dex"
    ];

    systemd.services.dex.serviceConfig.StateDirectory = "dex";

    services.dex = {
      enable = true;
      environmentFile = config.lollypops.secrets.files."dex/envfile".path;
      settings = {

        # External url
        issuer = "https://${cfg.host}";
        storage = {
          type = "sqlite3";
          config.file = "/var/lib/dex/dex.db";
        };

        web.http = "127.0.0.1:5556";

        # enablePasswordDB = true;
        # telemetry.http = "127.0.0.1:5558";

        logger = {
          #   level: "debug"
          format = "json"; # can also be "text"
        };

        frontend = {
          issuer = "https://${cfg.host}";
          logoURL = "https://0cx.de/dance.gif";
          theme = "dark";
        };

        connectors = [
          {
            type = "gitea";
            id = "gitea";
            name = "Gitea";
            config = {
              # Credentials can be string literals or pulled from the environment.
              clientID = "$GITEA_CLIENT_ID";
              clientSecret = "$GITEA_CLIENT_SECRET";
              redirectURI = "https://${cfg.host}/callback";
              baseURL = config.services.gitea.settings.server.ROOT_URL;
            };
          }
          {
            type = "github";
            id = "github";
            name = "GitHub";
            config = {
              useLoginAsID = true;
              clientID = "$GITHUB_CLIENT_ID";
              clientSecret = "$GITHUB_CLIENT_SECRET";
              redirectURI = "https://${cfg.host}/callback";
              orgs = [
                { name = "lounge-rocks"; }
                # {name = "krosse-flagge";}
              ];
            };
          }
        ];

        # TODO extract to option
        staticClients = [
          {
            id = "caddy";
            name = "caddy";
            redirectURIs = [
              "https://auth.0cx.de/oauth2/generic"
              "https://auth.0cx.de/oauth2/generic/authorization-code-callback"
            ];
            secretEnv = "CLIENT_SECRET_CADDY";
          }
          {
            id = "hedgedoc";
            name = "hedgedoc";
            redirectURIs = [ "https://${config.services.hedgedoc.settings.domain}/auth/oauth2/callback" ];
            secretEnv = "CLIENT_SECRET_HEDGEDOC";
          }
          {
            id = "vikunja";
            name = "vikunja";
            redirectURIs = [
              "${config.systemd.services.vikunja-api.environment.VIKUNJA_SERVICE_FRONTENDURL}auth/openid/dex"
            ];
            secretEnv = "CLIENT_SECRET_VIKUNJA";
          }
        ];
      };
    };
  };
}
