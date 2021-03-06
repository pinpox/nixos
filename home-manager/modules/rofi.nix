{ config, pkgs, lib, ... }:
let vars = import ./vars.nix;
in {
  programs.rofi = {

    # General
    enable = true;
    font = "${vars.font.normal.family} ${vars.font.normal.style} ${
        toString vars.font.size
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
        background = "#${vars.colors.Black}";
        # foreground = "#${vars.colors.Black}";
        separator = "#${vars.colors.Blue}";
        border = "#${vars.colors.Black}";
      };

      rows = {
        normal = {
          background = "#${vars.colors.Black}";
          foreground = "#${vars.colors.White}";
          backgroundAlt = "#${vars.colors.Black}";
          highlight = {
            background = "#${vars.colors.Grey}";
            foreground = "#${vars.colors.DarkGreen}";
          };
        };
        active = {
          background = "#${vars.colors.Black}";
          foreground = "#${vars.colors.Blue}";
          backgroundAlt = "#${vars.colors.Black}";
          highlight = {
            background = "#${vars.colors.Black}";
            foreground = "#${vars.colors.Blue}";
          };
        };
        urgent = {
          background = "#${vars.colors.Black}";
          foreground = "#${vars.colors.Red}";
          backgroundAlt = "#${vars.colors.Black}";
          highlight = {
            background = "#${vars.colors.Black}";
            foreground = "#${vars.colors.Red}";
          };
        };
      };
    };
  };
}
