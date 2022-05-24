{ colorscheme, config, lib, ... }:
with lib;
let

  cfg = config.pinpox.defaults.xresources;
in
{
  options.pinpox.defaults.xresources.enable = mkEnableOption "xresources defaults";

  config = mkIf cfg.enable {

    xresources.properties = {
      "color0" = "#${colorscheme.Black}";
      "color1" = "#${colorscheme.DarkGrey}";
      "color2" = "#${colorscheme.Grey}";
      "color3" = "#${colorscheme.BrightGrey}";
      "color4" = "#${colorscheme.DarkWhite}";
      "color5" = "#${colorscheme.White}";
      "color6" = "#${colorscheme.BrightWhite}";
      "color7" = "#${colorscheme.DarkGreen}";
      "color8" = "#${colorscheme.Red}";
      "color9" = "#${colorscheme.DarkYellow}";
      "color10" = "#${colorscheme.Yellow}";
      "color11" = "#${colorscheme.Green}";
      "color12" = "#${colorscheme.Cyan}";
      "color13" = "#${colorscheme.Blue}";
      "color14" = "#${colorscheme.Magenta}";
      "color15" = "#${colorscheme.BrightRed}";

      "foreground" = "#${colorscheme.White}";
      "background" = "#${colorscheme.Black}";

      "XTerm*faceName" = "monospace:style=medium";
      "XTerm*Background" = "#${colorscheme.Black}";
      "XTerm*cursorColor" = "#${colorscheme.Blue}";
      "XTerm*Foreground" = "#${colorscheme.White}";

      "XTerm*color0" = "#${colorscheme.Black}";
      "XTerm*color1" = "#${colorscheme.Red}";
      "XTerm*color2" = "#${colorscheme.Green}";
      "XTerm*color3" = "#${colorscheme.Yellow}";
      "XTerm*color4" = "#${colorscheme.Blue}";
      "XTerm*color5" = "#${colorscheme.Magenta}";
      "XTerm*color6" = "#${colorscheme.Cyan}";
      "XTerm*color7" = "#${colorscheme.White}";
      "XTerm*color8" = "#${colorscheme.BrightGrey}";
      "XTerm*color9" = "#${colorscheme.Red}";
      "XTerm*color10" = "#${colorscheme.Green}";
      "XTerm*color11" = "#${colorscheme.Yellow}";
      "XTerm*color12" = "#${colorscheme.Blue}";
      "XTerm*color13" = "#${colorscheme.Magenta}";
      "XTerm*color14" = "#${colorscheme.Cyan}";
      "XTerm*color15" = "#${colorscheme.DarkGreen}";
      "XTerm*color16" = "#${colorscheme.DarkYellow}";
      "XTerm*color17" = "#${colorscheme.BrightRed}";
      "XTerm*color18" = "#${colorscheme.DarkGrey}";
      "XTerm*color19" = "#${colorscheme.Grey}";
      "XTerm*color20" = "#${colorscheme.DarkWhite}";
      "XTerm*color21" = "#${colorscheme.BrightWhite}";
    };
  };
}
