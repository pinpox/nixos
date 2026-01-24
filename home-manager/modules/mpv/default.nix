{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.mpv;
in
{
  options.pinpox.programs.mpv.enable = mkEnableOption "mpv media player";

  config = mkIf cfg.enable {

    programs.mpv = {
      enable = true;

      config = {
        # Screenshot settings
        screenshot-directory = "~/Pictures";
        screenshot-format = "png";
        screenshot-template = "photo-%F-%T";

        # Low latency for camera preview
        profile = "low-latency";
        untimed = "yes";
      };

      # Rotation for webcam (applied to v4l2 protocol)
      profiles = {
        "protocol.av" = {
          vf = "rotate=PI";
        };
      };

      bindings = {
        # Screenshot bindings
        "s" = "screenshot";
        "MBTN_LEFT" = "screenshot";
      };
    };
  };
}
