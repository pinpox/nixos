{ config, lib, colorscheme, fonts, ... }:
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
      font = "${fonts.family} ${fonts.normal.style} ${
          toString (fonts.size * 2)
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
          background = "#${colorscheme.Black}";
          # foreground = "#${colorscheme.Black}";
          separator = "#${colorscheme.Blue}";
          border = "#${colorscheme.Black}";
        };

        rows = {
          normal = {
            background = "#${colorscheme.Black}";
            foreground = "#${colorscheme.White}";
            backgroundAlt = "#${colorscheme.Black}";
            highlight = {
              background = "#${colorscheme.Grey}";
              foreground = "#${colorscheme.DarkGreen}";
            };
          };
          active = {
            background = "#${colorscheme.Black}";
            foreground = "#${colorscheme.Blue}";
            backgroundAlt = "#${colorscheme.Black}";
            highlight = {
              background = "#${colorscheme.Black}";
              foreground = "#${colorscheme.Blue}";
            };
          };
          urgent = {
            background = "#${colorscheme.Black}";
            foreground = "#${colorscheme.Red}";
            backgroundAlt = "#${colorscheme.Black}";
            highlight = {
              background = "#${colorscheme.Black}";
              foreground = "#${colorscheme.Red}";
            };
          };
        };
      };
    };
  };
}
