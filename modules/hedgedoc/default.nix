{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.services.hedgedoc;
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
    lollypops.secrets.files."hedgedoc/envfile" = { };

    systemd.services.hedgedoc.serviceConfig.Environment = [
      # Allow creating on-the-fly by url
      "CMD_ALLOW_FREEURL=true"

      # Default permission of notes
      "CMD_DEFAULT_PERMISSION=limited"

      # Forbid anonymous usage
      "CMD_ALLOW_ANONYMOUS=false"

      # oauth2 with dex
      "CMD_OAUTH2_BASEURL=https://login.0cx.de"
      "CMD_OAUTH2_AUTHORIZATION_URL=https://login.0cx.de/auth"
      "CMD_OAUTH2_TOKEN_URL=https://login.0cx.de/token"
      "CMD_OAUTH2_USER_PROFILE_URL='https://login.0cx.de/userinfo'"
      "CMD_OAUTH2_PROVIDERNAME=dex"
      "CMD_OAUTH2_SCOPE='openid email profile'"
      "CMD_OAUTH2_USER_PROFILE_USERNAME_ATTR='preferred_username'"
      "CMD_OAUTH2_USER_PROFILE_DISPLAY_NAME_ATTR='name'"
      "CMD_OAUTH2_USER_PROFILE_EMAIL_ATTR='email'"
    ];

    # Create system user and group
    services.hedgedoc = {
      enable = true;
      environmentFile = "${config.lollypops.secrets.files."hedgedoc/envfile".path}";
      settings = {

        protocolUseSSL = true; # Use https when loading assets
        allowEmailRegister = false; # Disable email registration
        email = false; # Disable email login

        domain = "pads.0cx.de";
        host = "127.0.0.1";
        # port = 3000; # Default
        # allowOrigin = [ "localhost" ]; # TODO not sure if neeeded
        debug = true;

        db = {
          dialect = "sqlite";
          storage = "/var/lib/hedgedoc/db.sqlite";
        };

        useCDN = true;
      };
    };

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
