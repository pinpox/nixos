{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.services.mattermost;
in
{

  options.pinpox.services.mattermost = {
    enable = mkEnableOption "Mattermost server";
  };

  config = mkIf cfg.enable {

    services.mattermost = {
      enable = true;

      siteUrl = "https://mm.0cx.de";
      listenAddress = "127.0.0.1:8065";

      # TODO reevaluate option on fresh install
      # Database was created before this option existed. Also using this
      # requires to put add the password to the nix store.
      localDatabaseCreate = false;

      extraConfig = {
        ServiceSettings = {
          EnableEmailInvitations = true;
          EnableOAuthServiceProvider = true;
          TrustedProxyIPHeader = [ "X-Forwarded-For" "X-Real-IP" ];
          AllowCorsFrom = "*";
        };

        FileSettings.Directory = "/var/lib/mattermost/files";
      };
    };


    lollypops.secrets.files."mattermost/envfile" = { };

    systemd.services.mattermost = {

      serviceConfig = {

        EnvironmentFile = config.lollypops.secrets.files."mattermost/envfile".path;

        Environment = [

          # TODO Check syntax for header

          # Secret envfile contains:
          # MM_EMAILSETTINGS_CONNECTIONSECURITY=
          # MM_EMAILSETTINGS_ENABLEPREVIEWMODEBANNER=
          # MM_EMAILSETTINGS_ENABLESMTPAUTH=
          # MM_EMAILSETTINGS_FEEDBACKEMAIL=
          # MM_EMAILSETTINGS_PUSHNOTIFICATIONCONTENTS=
          # MM_EMAILSETTINGS_REPLYTOADDRESS=
          # MM_EMAILSETTINGS_SENDEMAILNOTIFICATIONS=
          # MM_EMAILSETTINGS_SMTPPASSWORD=
          # MM_EMAILSETTINGS_SMTPPORT=
          # MM_EMAILSETTINGS_SMTPSERVER=
          # MM_EMAILSETTINGS_SMTPUSERNAME=
          # MM_FILESETTINGS_PUBLICLINKSALT=
          # MM_SQLSETTINGS_ATRESTENCRYPTKEY=
          # MM_SQLSETTINGS_DATASOURCE=
          # MM_EXTRA_SQLSETTINGS_DB_PASSWORD=
        ];
      };
    };
  };
}
