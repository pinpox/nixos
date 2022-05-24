{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.xscreensaver;
in
{
  options.pinpox.programs.xscreensaver.enable = mkEnableOption "xscreensaver";

  config = mkIf cfg.enable {
    # Screensaver and lock
    services.xscreensaver = {
      enable = true;
      settings = {
        fadeTicks = 20;
        lock = false;
        mode = "blank";
      };
    };
  };
}
