{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.services.gitea;
in
{

  options.pinpox.services.gitea = {
    enable = mkEnableOption "gitea config";
    host = mkOption {
      type = types.str;
      default = "git.0cx.de";
      description = "Host serving gitea";
      example = "git.0cx.de";
    };
  };

  config = mkIf cfg.enable {

    # Reverse proxy
    services.caddy.virtualHosts."${cfg.host
    }".extraConfig = "reverse_proxy ${config.services.gitea.settings.server.HTTP_ADDR}:${builtins.toString config.services.gitea.settings.server.HTTP_PORT}";

    # Backups
    pinpox.services.restic-client.backup-paths-offsite = [ "/var/lib/gitea" ];

    lollypops.secrets.files."gitea/mailer-pw" = {
      owner = "gitea";
      path = "/var/lib/gitea/mailer-pw";
    };
    services.gitea = {

      enable = true;
      mailerPasswordFile = "${config.lollypops.secrets.files."gitea/mailer-pw".path}";

      settings = {
        server = {
          ROOT_URL = "https://${cfg.host}";
          HTTP_PORT = 3333;
          HTTP_ADDR = "127.0.0.1";
        };
        service = {
          DISABLE_REGISTRATION = true;
          REQUIRE_SIGNIN_VIEW = true;
          DOMAIN = cfg.host;
        };

        mailer = {
          ENABLED = true;
          FROM = "git@0cx.de";
          PROTOCOL = "smtp";
          IS_TLS_ENABLED = false;
          USER = "mail@0cx.de";
          SMTP_ADDR = "r19.hallo.cloud:587";
        };
        markdown.ENABLE_MATH = true;
      };
    };
  };
}
