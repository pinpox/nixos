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
    services.caddy.virtualHosts."${cfg.host}".extraConfig =
      with config.services.gitea.settings.server;
      "reverse_proxy ${HTTP_ADDR}:${toString HTTP_PORT}";

    # Backups
    pinpox.services.restic-client.backup-paths-offsite = [ "/var/lib/gitea" ];

    clan.core.vars.generators."gitea" = {
      files.mailer-pw.owner = "gitea";
      prompts.mailer-pw = {
        type = "hidden";
        persist = true;
        description = "Mail password for gitea@pinpox.com";
      };
    };

    services.gitea = {

      enable = true;
      mailerPasswordFile = "${config.clan.core.vars.generators."gitea".files."mailer-pw".path}";

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
          PROTOCOL = "smtps";
          SMTP_ADDR = "mail.pinpox.com";
          SMTP_PORT = 465;
          USER = "gitea@pinpox.com";
          FROM = "Gitea <gitea@pinpox.com>";
        };
        markdown.ENABLE_MATH = true;
      };
    };
  };
}
