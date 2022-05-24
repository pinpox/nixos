{ config, pkgs, lib, ... }:
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
  };
}
