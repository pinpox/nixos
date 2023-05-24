{ config, lib, ... }:
with lib;
let

  cfg = config.pinpox.defaults.xresources;
in
{
  options.pinpox.defaults.xresources.enable = mkEnableOption "xresources defaults";

  config = mkIf cfg.enable {


    # ANSI Colors
    # Black
    # Red
    # Green
    # Yellow
    # Blue
    # Purple
    # Cyan
    # White



    xresources.properties = {
      # Black
      "color0" = "#${config.pinpox.colors.Black}";
      "color8" = "#${config.pinpox.colors.BrightBlack}";

      # Red
      "color1" = "#${config.pinpox.colors.Red}";
      "color9" = "#${config.pinpox.colors.BrightRed}";

      #Green
      "color2" = "#${config.pinpox.colors.Green}";
      "color10" = "#${config.pinpox.colors.BrightGreen}";

      # Yellow
      "color3" = "#${config.pinpox.colors.Yellow}";
      "color11" = "#${config.pinpox.colors.BrightYellow}";

      # Blue
      "color4" = "#${config.pinpox.colors.Blue}";
      "color12" = "#${config.pinpox.colors.BrightBlue}";

      # Magenta
      "color5" = "#${config.pinpox.colors.Magenta}";
      "color13" = "#${config.pinpox.colors.BrightMagenta}";

      # Cyan
      "color6" = "#${config.pinpox.colors.Cyan}";
      "color14" = "#${config.pinpox.colors.BrightCyan}";

      # White
      "color7" = "#${config.pinpox.colors.White}";
      "color15" = "#${config.pinpox.colors.BrightWhite}";

      "foreground" = "#${config.pinpox.colors.White}";
      "background" = "#${config.pinpox.colors.Black}";

      "XTerm*faceName" = "monospace:style=medium";
      "XTerm*Background" = "#${config.pinpox.colors.Black}";
      "XTerm*cursorColor" = "#${config.pinpox.colors.Blue}";
      "XTerm*Foreground" = "#${config.pinpox.colors.White}";

      "XTerm*color0" = "#${config.pinpox.colors.Black}";
      "XTerm*color8" = "#${config.pinpox.colors.BrightBlack}";

      "XTerm*color1" = "#${config.pinpox.colors.Red}";
      "XTerm*color9" = "#${config.pinpox.colors.BrightRed}";

      "XTerm*color2" = "#${config.pinpox.colors.Green}";
      "XTerm*color10" = "#${config.pinpox.colors.BrightGreen}";

      "XTerm*color3" = "#${config.pinpox.colors.Yellow}";
      "XTerm*color11" = "#${config.pinpox.colors.BrightYellow}";

      "XTerm*color4" = "#${config.pinpox.colors.Blue}";
      "XTerm*color12" = "#${config.pinpox.colors.BrightBlue}";

      "XTerm*color5" = "#${config.pinpox.colors.Magenta}";
      "XTerm*color13" = "#${config.pinpox.colors.BrightMagenta}";

      "XTerm*color6" = "#${config.pinpox.colors.Cyan}";
      "XTerm*color14" = "#${config.pinpox.colors.BrightCyan}";

      "XTerm*color7" = "#${config.pinpox.colors.White}";
      "XTerm*color15" = "#${config.pinpox.colors.BrightWhite}";
    };
  };
}
