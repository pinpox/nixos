{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.defaults.sound;
in
{

  options.pinpox.defaults.sound = { enable = mkEnableOption "sound defaults"; };
  config = mkIf cfg.enable {

    # Enable sound.
    sound.enable = true;
    environment.systemPackages = [ pkgs.qjackctl ];

    # Use pipeware to emulate jack and pulseaudio
    services.pipewire = {
      enable = true;
      jack.enable = true;
      pulse.enable = true;
    };
  };
}
