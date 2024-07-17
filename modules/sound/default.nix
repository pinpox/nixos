{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.sound;
in
{

  options.pinpox.defaults.sound = {
    enable = mkEnableOption "sound defaults";
  };
  config = mkIf cfg.enable {

    environment.systemPackages = [ pkgs.qjackctl ];

    # Use pipeware to emulate jack and pulseaudio
    services.pipewire = {
      enable = true;
      jack.enable = true;
      pulse.enable = true;
      alsa.enable = true;
    };

    # Use noisetorch (RNnoise) to create a virtual source with noise removal
    programs.noisetorch.enable = true;

    # services.pipewire.wireplumber.enable = true;

    # environment.etc."wireplumber/main.lua.d/90-suspend-timeout.lua" = {
    #   text = ''
    #     session.suspend-timeout-seconds = 0
    #   '';
    # };
  };
}
