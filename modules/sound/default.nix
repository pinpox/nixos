{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.defaults.sound;
in {

  options.pinpox.defaults.sound = { enable = mkEnableOption "sound defaults"; };
  config = mkIf cfg.enable {

    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
      extraModules = [ pkgs.pulseaudio-modules-bt ];
    };
  };
}
