{ config, lib, pkgs, ... }:
with lib;
let cfg = config.pinpox.services.vikunja;
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

    # Reverse proxy
    services.caddy.virtualHosts."${cfg.host}".extraConfig = ''
      @paths {
        path /api/* /.well-known/* /dav/*
      }

      handle @paths {
        reverse_proxy ${config.systemd.services.vikunja-api.environment.VIKUNJA_SERVICE_INTERFACE }
      }

      handle {
        encode zstd gzip
        root * ${config.services.vikunja.package-frontend}
        try_files {path} index.html
        file_server
      }
    '';

    # Vikunja doesn't allow setting openid configuration parameters (e.g.
    # openid_secret) via environment variables, so we have to treat the
    # config.yaml as a secret and can't use the nixos service

    # User and group
    users.users.vikunja = {
      isSystemUser = true;
      description = "vikunja system user";
      group = "vikunja";
    };

    users.groups.vikunja = { name = "vikunja"; };

    lollypops.secrets.files = {
      "vikunja/config" = {
        owner = "vikunja";
        group-name = "vikunja";
      };

      # Additional envfile contains secrets:
      # VIKUNJA_METRICS_PASSWORD
      # VIKUNJA_MAILER_PASSWORD
      "vikunja/envfile" = { };
    };

    systemd.services.vikunja-api = {
      description = "vikunja-api";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.vikunja-api ];
      restartTriggers = [
        config.lollypops.secrets.files."vikunja/config".path
        config.lollypops.secrets.files."vikunja/envfile".path
      ];

      environment = {

        # VIKUNJA_LOG_LEVEL = "debug";

        # General
        VIKUNJA_SERVICE_FRONTENDURL = "https://${cfg.host}/";
        VIKUNJA_SERVICE_INTERFACE = "127.0.0.1:3456";
        VIKUNJA_SERVICE_TIMEZONE = "Europe/Berlin";
        VIKUNJA_DEFAULTSETTINGS_DISCOVERABLE_BY_NAME = "true";
        VIKUNJA_DEFAULTSETTINGS_DISCOVERABLE_BY_EMAIL = "true";
        VIKUNJA_DEFAULTSETTINGS_EMAIL_REMINDERS_ENABLED = "true";
        VIKUNJA_DEFAULTSETTINGS_OVERDUE_TASKS_REMINDERS_enabled = "true";
        VIKUNJA_DEFAULTSETTINGS_OVERDUE_TASKS_REMINDERS_TIME = "10:00";
        VIKUNJA_DEFAULTSETTINGS_WEEK_START = "1";
        VIKUNJA_FILES_BASEPATH = "/var/lib/vikunja/files";

        # Database
        VIKUNJA_DATABASE_DATABASE = "vikunja";
        VIKUNJA_DATABASE_HOST = "localhost";
        VIKUNJA_DATABASE_PATH = "/var/lib/vikunja/vikunja.db";
        VIKUNJA_DATABASE_TYPE = "sqlite";
        VIKUNJA_DATABASE_USER = "vikunja";

        # Mailer
        VIKUNJA_MAILER_ENABLED = "true";
        VIKUNJA_MAILER_HOST = "smtp.sendgrid.net";
        VIKUNJA_MAILER_USERNAME = "apikey";
        VIKUNJA_MAILER_FROMMAIL = "todo@0cx.de";
        VIKUNJA_MAILER_PORT = "465";
        VIKUNJA_MAILER_AUTHTYPE = "plain";
        VIKUNJA_MAILER_SKIPTLSVERIFY = "false";
        VIKUNJA_MAILER_FORCESSL = "true";

        # Monitoring Metrics
        VIKUNJA_METRICS_ENABLED = "true";
        VIKUNJA_METRICS_USERNAME = "prometheus";
      };

      serviceConfig = {

        Type = "simple";
        User = "vikunja";
        Group = "vikunja";
        StateDirectory = "vikunja";
        ExecStart = "${pkgs.vikunja-api}/bin/vikunja";
        Restart = "always";
        EnvironmentFile = [ config.lollypops.secrets.files."vikunja/envfile".path ];
        BindReadOnlyPaths = [ "${config.lollypops.secrets.files."vikunja/config".path}:/etc/vikunja/config.yaml" ];

      };
    };
  };
}
