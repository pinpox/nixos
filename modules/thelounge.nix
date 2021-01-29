{ config, pkgs, lib, ... }: {
  services.thelounge = {

    enable = true;
    port = 9090; # Default port
    private = true;
    extraConfig = {
      host = "127.0.0.1";
      reverseProxy = true;

      # TODO default network to mattermost brideg
      # defaults = {};
      theme = "morning";
    };
  };
}
