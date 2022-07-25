{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.picom;
in
{
  options.pinpox.programs.picom.enable = mkEnableOption "picom compositor";

  config = mkIf cfg.enable {
    # Picom X11 compositor
    services.picom = {
      backend = "glx";
      enable = true;
      # package = ;

      activeOpacity = 1.0;
      shadow = true;
    };
  };
}
