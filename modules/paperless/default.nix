{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.paperless;
  paperlessPermsApp = ./django-apps;
  paperlessCfg = config.services.paperless;
  paperlessPythonPath = "${paperlessCfg.package.python.pkgs.makePythonPath paperlessCfg.package.propagatedBuildInputs}:${paperlessCfg.package}/lib/paperless-ngx/src:${paperlessPermsApp}";
in
{

  options.pinpox.services.paperless = {
    enable = mkEnableOption "paperless-ngx document management";

    host = mkOption {
      type = types.str;
      default = "paper.pablo.tools";
      description = "Host serving paperless-ngx";
      example = "paper.pablo.tools";
    };
  };

  config = mkIf cfg.enable {

    clan.core.vars.generators."paperless" = {
      files.password = { };
      runtimeInputs = with pkgs; [
        coreutils
        xkcdpass
      ];
      script = ''
        mkdir -p $out
        xkcdpass -d- > $out/password
      '';
    };

    services.paperless = {
      enable = true;
      address = "127.0.0.1";
      port = 28981;
      passwordFile = config.clan.core.vars.generators."paperless".files."password".path;
      settings = {
        PAPERLESS_URL = "https://${cfg.host}";
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_CONSUMER_RECURSIVE = true;
        PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;
        PAPERLESS_ADMIN_USER = "pinpox";
        PAPERLESS_ENABLE_HTTP_REMOTE_USER = true;
        PAPERLESS_HTTP_REMOTE_USER_HEADER_NAME = "HTTP_REMOTE_USER";
        PAPERLESS_LOGOUT_REDIRECT_URL = "/";
        PAPERLESS_APPS = "paperless_perms.apps.PaperlessPermsConfig";
      };
    };

    # Add the perms Django app to PYTHONPATH for all paperless services
    systemd.services.paperless-web.environment.PYTHONPATH = lib.mkForce paperlessPythonPath;
    systemd.services.paperless-task-queue.environment.PYTHONPATH = paperlessPythonPath;
    systemd.services.paperless-consumer.environment.PYTHONPATH = paperlessPythonPath;
    systemd.services.paperless-scheduler.environment.PYTHONPATH = paperlessPythonPath;

    services.caddy = {
      enable = true;
      virtualHosts."${cfg.host}".extraConfig = ''
        forward_auth http://127.0.0.1:9091 {
          uri /api/authz/forward-auth
          copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
        }
        reverse_proxy ${config.services.paperless.address}:${toString config.services.paperless.port}
      '';
    };

    pinpox.services.restic-client.backup-paths-offsite = [
      "${config.services.paperless.dataDir}"
    ];
  };
}
