{
  lib,
  pkgs,
  config,
  system-config,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.obs-studio;
  droidcam-port = 5201;
in
{
  options.pinpox.programs.obs-studio.enable = mkEnableOption "obs-studio";

  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = (builtins.elem droidcam-port system-config.networking.firewall.allowedTCPPorts);
        message = "Port ${toString droidcam-port}/tcp is not open in the firewall, but required by droidcam";
      }
    ];

    home.packages = [
      pkgs.uxplay # AirPlay Unix mirroring server
    ];

    programs.obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        obs-pipewire-audio-capture
        droidcam-obs
        wlrobs
        # obs-vintage-filter
        # obs-teleport
        # obs-backgroundremoval
        input-overlay
      ];
    };
  };
}
