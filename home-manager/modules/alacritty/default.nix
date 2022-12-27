{ config, lib, fonts, colorscheme, ... }:
with lib;
let
  cfg = config.pinpox.programs.alacritty;
in
{

  options.pinpox.programs.alacritty.enable = mkEnableOption "alacritty terminal emulator";

  config = mkIf cfg.enable {
    # Alacritty
    programs.alacritty = {
      enable = true;
      settings = {

        scrolling.history = 10000;
        env.TERM = "xterm-256color";

        window = {
          opacity = 0.85;
          dimensions = {
            lines = 20;
            columns = 80;
          };
          padding = {
            x = 3;
            y = 3;
          };
        };

        font = {
          normal = {
            family = "Recursive Mono Linear Static";
            # style = fonts.normal.style;
          };
          bold = {
            family = "Recursive Mono Linear Static";
            style = fonts.bold.style;
          };
          italic = {
            family = "Recursive Mono Linear Static";
            style = fonts.italic.style;
          };
        };

        cursor = { style = "Beam"; };
        colors = {
          primary = {
            background = "0x${colorscheme.Black}";
            foreground = "0x${colorscheme.White}";
          };
          cursor = {
            text = "0x${colorscheme.Black}";
            cursor = "0x${colorscheme.Blue}";
          };
          normal = {
            black = "0x${colorscheme.Black}";
            red = "0x${colorscheme.Red}";
            green = "0x${colorscheme.Green}";
            yellow = "0x${colorscheme.Yellow}";
            blue = "0x${colorscheme.Blue}";
            magenta = "0x${colorscheme.Magenta}";
            cyan = "0x${colorscheme.Cyan}";
            white = "0x${colorscheme.White}";
          };
          bright = {
            black = "0x${colorscheme.BrightBlack}";
            red = "0x${colorscheme.BrightRed}";
            green = "0x${colorscheme.BrightGreen}";
            yellow = "0x${colorscheme.BrightYellow}";
            blue = "0x${colorscheme.BrightBlue}";
            magenta = "0x${colorscheme.BrightMagenta}";
            cyan = "0x${colorscheme.BrightCyan}";
            white = "0x${colorscheme.BrightWhite}";
          };
        };

        key_bindings = [
          # Clear terminal
          # {
          #   key = "K";
          #   mods = "Control";
          #   chars = "\\x0c";
          # }
        ];
      };
    };
  };
}
