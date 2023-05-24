{ config, lib, ... }:
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
            family = "Berkeley Mono";
            # style = config.pinpox.font.normal.style;
          };
          bold = {
            family = "Berkeley Mono";
            style = config.pinpox.font.bold.style;
          };
          italic = {
            family = "Berkeley Mono";
            style = config.pinpox.font.italic.style;
          };
          size = 10;
        };

        cursor = { style = "Beam"; };
        colors = {
          primary = {
            background = "0x${config.pinpox.colors.Black}";
            foreground = "0x${config.pinpox.colors.White}";
          };
          cursor = {
            text = "0x${config.pinpox.colors.Black}";
            cursor = "0x${config.pinpox.colors.Blue}";
          };
          normal = {
            black = "0x${config.pinpox.colors.Black}";
            red = "0x${config.pinpox.colors.Red}";
            green = "0x${config.pinpox.colors.Green}";
            yellow = "0x${config.pinpox.colors.Yellow}";
            blue = "0x${config.pinpox.colors.Blue}";
            magenta = "0x${config.pinpox.colors.Magenta}";
            cyan = "0x${config.pinpox.colors.Cyan}";
            white = "0x${config.pinpox.colors.White}";
          };
          bright = {
            black = "0x${config.pinpox.colors.BrightBlack}";
            red = "0x${config.pinpox.colors.BrightRed}";
            green = "0x${config.pinpox.colors.BrightGreen}";
            yellow = "0x${config.pinpox.colors.BrightYellow}";
            blue = "0x${config.pinpox.colors.BrightBlue}";
            magenta = "0x${config.pinpox.colors.BrightMagenta}";
            cyan = "0x${config.pinpox.colors.BrightCyan}";
            white = "0x${config.pinpox.colors.BrightWhite}";
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
