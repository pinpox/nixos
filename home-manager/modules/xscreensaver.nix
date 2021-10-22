{ config, pkgs, lib, ... }: {
  # Screensaver and lock
  services.xscreensaver = {
    enable = true;
    settings = {
      fadeTicks = 20;
      lock = false;
      mode = "blank";
    };
  };
}
