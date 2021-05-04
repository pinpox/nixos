{ config, pkgs, lib, ... }:
let vars = import ./vars.nix;
in {
  # Alacritty
  programs.alacritty = {
    enable = true;
    settings = {

      scrolling.history = 10000;
      env.TERM = "xterm-256color";

      background_opacity = 0.85;
      window = {
        dimensions = {
          lines = 20;
          columns = 80;
        };
        padding = {
          x = 3;
          y = 3;
        };
      };

      font = vars.font;
      cursor = { style = "Beam"; };
      colors = {
        primary = {
          background = "0x${vars.colors.Black}";
          foreground = "0x${vars.colors.White}";
        };
        cursor = {
          text = "0x${vars.colors.Black}";
          cursor = "0x${vars.colors.Blue}";
        };
        normal = {
          black = "0x${vars.colors.Black}";
          red = "0x${vars.colors.Red}";
          green = "0x${vars.colors.Green}";
          yellow = "0x${vars.colors.Yellow}";
          blue = "0x${vars.colors.Blue}";
          magenta = "0x${vars.colors.Magenta}";
          cyan = "0x${vars.colors.Cyan}";
          white = "0x${vars.colors.White}";
        };
        bright = {
          black = "0x${vars.colors.BrightGrey}";
          red = "0x${vars.colors.DarkYellow}";
          green = "0x${vars.colors.DarkGrey}";
          yellow = "0x${vars.colors.Grey}";
          blue = "0x${vars.colors.DarkWhite}";
          magenta = "0x${vars.colors.BrightWhite}";
          cyan = "0x${vars.colors.BrightRed}";
          white = "0x${vars.colors.DarkGreen}";
        };
      };

      key_bindings = [
        # Clear terminal
        {
          key = "K";
          mods = "Control";
          chars = "\\x0c";
        }
      ];
    };
  };
}
