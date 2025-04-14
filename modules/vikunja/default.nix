{
  config,
  lib,
  pinpox-utils,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.vikunja;
in
{

  options.pinpox.services.vikunja = {
    enable = mkEnableOption "vikunja config";
    host = mkOption {
      type = types.str;
      default = "todo.0cx.de";
      description = "Host serving vikunja";
      example = "tasks.0cx.de";
    };
  };

  config = mkIf cfg.enable {

    services.caddy.virtualHosts."${cfg.host}".extraConfig =
      "reverse_proxy localhost:${toString config.services.vikunja.port}";

    clan.core.vars.generators."vikunja" = pinpox-utils.mkEnvGenerator [
      "VIKUNJA_AUTH_OPENID_PROVIDERS_DEX_CLIENTID"
      "VIKUNJA_AUTH_OPENID_PROVIDERS_DEX_CLIENTSECRET"
      "VIKUNJA_METRIC_PASSWORD"
      "VIKUNJA_MAILER_PASSWORD"
    ];

    services.vikunja = {
      enable = true;
      port = 3456;
      environmentFiles = [ config.clan.core.vars.generators."vikunja".files."envfile".path ];

      frontendScheme = "https";
      frontendHostname = cfg.host;

      settings = {

        service.timezone = "Europe/Berlin";
        files.basepath = "/var/lib/vikunja/files";

        defaultsettings = {
          discoverable_by_name = true;
          discoverable_by_email = true;
          email_reminders_enabled = true;
          overdue_tasks_reminders_enabled = true;
          overdue_tasks_reminders_time = "10:00";
          week_start = "1";
        };

        mailer = {
          enabled = true;
          host = "smtp.sendgrid.net";
          username = "apikey";
          frommail = "todo@0cx.de";
          port = "587";
          authtype = "plain";
          skiptlsverify = "false";
          forcessl = true;
        };

        metrics = {
          enabled = true;
          username = "prometheus";
        };

        auth = {
          local.enabled = false;
          openid = {
            enabled = true;
            redirect_url = "https://todo.0cx.de/auth/openid/";
            providers.dex = {
              authurl = "https://login.0cx.de";
              name = "dex";
            };
          };
        };
      };
    };
  };
}
