{ colorscheme, config, lib, ... }:
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
      "color0" = "#${colorscheme.Black}";
      "color8" = "#${colorscheme.BrightBlack}";

      # Red
      "color1" = "#${colorscheme.Red}";
      "color9" = "#${colorscheme.BrightRed}";

      #Green
      "color2" = "#${colorscheme.Green}";
      "color10" = "#${colorscheme.BrightGreen}";

      # Yellow
      "color3" = "#${colorscheme.Yellow}";
      "color11" = "#${colorscheme.BrightYellow}";

      # Blue
      "color4" = "#${colorscheme.Blue}";
      "color12" = "#${colorscheme.BrightBlue}";

      # Magenta
      "color5" = "#${colorscheme.Magenta}";
      "color13" = "#${colorscheme.BrightMagenta}";

      # Cyan
      "color6" = "#${colorscheme.Cyan}";
      "color14" = "#${colorscheme.BrightCyan}";

      # White
      "color7" = "#${colorscheme.White}";
      "color15" = "#${colorscheme.BrightWhite}";

      "foreground" = "#${colorscheme.White}";
      "background" = "#${colorscheme.Black}";

      "XTerm*faceName" = "monospace:style=medium";
      "XTerm*Background" = "#${colorscheme.Black}";
      "XTerm*cursorColor" = "#${colorscheme.Blue}";
      "XTerm*Foreground" = "#${colorscheme.White}";

      "XTerm*color0" = "#${colorscheme.Black}";
      "XTerm*color8" = "#${colorscheme.BrightBlack}";

      "XTerm*color1" = "#${colorscheme.Red}";
      "XTerm*color9" = "#${colorscheme.BrightRed}";

      "XTerm*color2" = "#${colorscheme.Green}";
      "XTerm*color10" = "#${colorscheme.BrightGreen}";

      "XTerm*color3" = "#${colorscheme.Yellow}";
      "XTerm*color11" = "#${colorscheme.BrightYellow}";

      "XTerm*color4" = "#${colorscheme.Blue}";
      "XTerm*color12" = "#${colorscheme.BrightBlue}";

      "XTerm*color5" = "#${colorscheme.Magenta}";
      "XTerm*color13" = "#${colorscheme.BrightMagenta}";

      "XTerm*color6" = "#${colorscheme.Cyan}";
      "XTerm*color14" = "#${colorscheme.BrightCyan}";

      "XTerm*color7" = "#${colorscheme.White}";
      "XTerm*color15" = "#${colorscheme.BrightWhite}";
    };
  };
}
