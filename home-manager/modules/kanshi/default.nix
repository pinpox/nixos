{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.kanshi;
in
{
  options.pinpox.programs.kanshi.enable = mkEnableOption "kanshi screen setup";

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ kanshi ];

    # output eDP-1 mode 1920x1080 position 0,0
    # output DP-1 mode 2560x1440 position 1080,0
    # output DP-2 mode 2560x1440 position 3640,0

    services.kanshi = {
      enable = true;
      settings = [
        {
          profile.name = "laptop-only";
          profile.outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1080@60Hz";
            }
          ];
        }
        {
          profile.name = "laptop-external-right";
          profile.outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1080@60Hz";
              position = "0,0";
              status = "enable";
            }
            {
              criteria = "DP-2";
              mode = "2560x1440@165Hz";
              position = "1920,0";
              status = "enable";
            }
          ];
        }
      ];
    };
  };
}
