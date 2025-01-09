{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.services.hedgedoc;
in
{

  options.pinpox.services.hedgedoc = {
    enable = mkEnableOption "Hedgedoc server";
  };

  config = mkIf cfg.enable {

    # env file contains:
    # CMD_SESSION_SECRET
    # CMD_OAUTH2_CLIENT_ID
    # CMD_OAUTH2_CLIENT_SECRET=

    clan.core.vars.generators."hedgedoc" = {
      files.envfile = { };
    };

    systemd.services.hedgedoc.serviceConfig.Environment = [
      # Allow creating on-the-fly by url
      "CMD_ALLOW_FREEURL=true"

      # Default permission of notes
      "CMD_DEFAULT_PERMISSION=limited"

      # Forbid anonymous usage
      "CMD_ALLOW_ANONYMOUS=false"

      # oauth2 with dex
      "CMD_OAUTH2_BASEURL=https://${config.pinpox.services.dex.host}"
      "CMD_OAUTH2_AUTHORIZATION_URL=https://${config.pinpox.services.dex.host}/auth"
      "CMD_OAUTH2_TOKEN_URL=https://${config.pinpox.services.dex.host}/token"
      "CMD_OAUTH2_USER_PROFILE_URL='https://${config.pinpox.services.dex.host}/userinfo'"
      "CMD_OAUTH2_PROVIDERNAME=dex"
      "CMD_OAUTH2_SCOPE='openid email profile'"
      "CMD_OAUTH2_USER_PROFILE_USERNAME_ATTR='preferred_username'"
      "CMD_OAUTH2_USER_PROFILE_DISPLAY_NAME_ATTR='name'"
      "CMD_OAUTH2_USER_PROFILE_EMAIL_ATTR='email'"
    ];

    # Create system user and group
    services.hedgedoc = {
      enable = true;

      environmentFile = "${config.clan.core.vars.generators."hedgedoc".files."envfile".path}";

      settings = {

        protocolUseSSL = true; # Use https when loading assets
        allowEmailRegister = false; # Disable email registration
        email = false; # Disable email login

        domain = "pads.0cx.de";
        host = "127.0.0.1";
        # port = 3000; # Default
        debug = true;

        db = {
          dialect = "sqlite";
          storage = "/var/lib/hedgedoc/db.sqlite";
        };

        useCDN = true;
      };
    };

    # Backup SQLite databse
    pinpox.services.restic-client.backup-paths-offsite = [
      config.services.hedgedoc.settings.db.storage
    ];

    # systemd.services.hedgedoc-git-sync = {
    #   serviceConfig = {
    #     Type = "oneshot";
    #     Environment = [
    #       "GIT_SSH_COMMAND='ssh -i private_key_file'"
    #     ];
    #   };
    #   path = with pkgs; [ bash ];
    #   script = ''
    #     echo "RUNNING IN "
    #     pwd
    #   '';
    # };

    # systemd.timers.hedgedoc-git-sync = {
    #   wantedBy = [ "timers.target" ];
    #   partOf = [ "hedgedoc-git-sync.service" ];
    #   timerConfig = {
    #     OnCalendar = "*:0/1";
    #     Unit = "hedgedoc-git-sync.service";
    #   };
    # };
  };
}
