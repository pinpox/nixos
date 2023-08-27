{ config, lib, ... }:
with lib;
let cfg = config.pinpox.services.thelounge;
in
{

  options.pinpox.services.thelounge = {
    enable = mkEnableOption "The Lounge IRC client and bouncer";
  };

  config = mkIf cfg.enable {

    services.thelounge = {

      enable = true;
      port = 9090; # Default port
      public = false;
      extraConfig = {
        host = "127.0.0.1";
        reverseProxy = true;

        # TODO default network to mattermost brideg
        # defaults = {};
        theme = "morning";
      };
    };

    pinpox.services.restic-client.backup-paths-offsite = [
      "/var/lib/thelounge/certificates"
      "/var/lib/thelounge/config.js"
      # Don't backup logs for now - too big.
      # "/var/lib/thelounge/logs"
      # "/var/lib/thelounge/packages"
      "/var/lib/thelounge/sts-policies.json"
      "/var/lib/thelounge/users"
      "/var/lib/thelounge/vapid.json"
    ];
  };

}
