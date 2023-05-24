{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.rofi;
in
{

  options.pinpox.programs.rofi.enable = mkEnableOption "rofi launcher";

  config = mkIf cfg.enable {
    programs.rofi = {

      # General
      enable = true;
      font = "${config.pinpox.font.family} ${config.pinpox.font.normal.style} ${
          toString (config.pinpox.font.size * 2)
        }px";
      cycle = true;
      # extraConfig = "";

      # Geometry
      fullscreen = true;
      borderWidth = 0;
      lines = 3;
      padding = 400;
      rowHeight = 2;

      colors = {

        window = {
          background = "#${config.pinpox.colors.Black}";
          # foreground = "#${config.pinpox.colors.Black}";
          separator = "#${config.pinpox.colors.Blue}";
          border = "#${config.pinpox.colors.Black}";
        };

        rows = {
          normal = {
            background = "#${config.pinpox.colors.Black}";
            foreground = "#${config.pinpox.colors.White}";
            backgroundAlt = "#${config.pinpox.colors.Black}";
            highlight = {
              background = "#${config.pinpox.colors.BrightBlack}";
              foreground = "#${config.pinpox.colors.DarkGreen}";
            };
          };
          active = {
            background = "#${config.pinpox.colors.Black}";
            foreground = "#${config.pinpox.colors.Blue}";
            backgroundAlt = "#${config.pinpox.colors.Black}";
            highlight = {
              background = "#${config.pinpox.colors.Black}";
              foreground = "#${config.pinpox.colors.Blue}";
            };
          };
          urgent = {
            background = "#${config.pinpox.colors.Black}";
            foreground = "#${config.pinpox.colors.Red}";
            backgroundAlt = "#${config.pinpox.colors.Black}";
            highlight = {
              background = "#${config.pinpox.colors.Black}";
              foreground = "#${config.pinpox.colors.Red}";
            };
          };
        };
      };
    };
  };
}
