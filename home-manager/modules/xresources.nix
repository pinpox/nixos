{ config, pkgs, lib, ... }:
let vars = import ./vars.nix;
in
{
  xresources.properties = {
    "color0" = "#${vars.colors.Black}";
    "color1" = "#${vars.colors.DarkGrey}";
    "color2" = "#${vars.colors.Grey}";
    "color3" = "#${vars.colors.BrightGrey}";
    "color4" = "#${vars.colors.DarkWhite}";
    "color5" = "#${vars.colors.White}";
    "color6" = "#${vars.colors.BrightWhite}";
    "color7" = "#${vars.colors.DarkGreen}";
    "color8" = "#${vars.colors.Red}";
    "color9" = "#${vars.colors.DarkYellow}";
    "color10" = "#${vars.colors.Yellow}";
    "color11" = "#${vars.colors.Green}";
    "color12" = "#${vars.colors.Cyan}";
    "color13" = "#${vars.colors.Blue}";
    "color14" = "#${vars.colors.Magenta}";
    "color15" = "#${vars.colors.BrightRed}";

    "foreground" = "#${vars.colors.White}";
    "background" = "#${vars.colors.Black}";

    "XTerm*faceName" = "monospace:style=medium";
    "XTerm*Background" = "#${vars.colors.Black}";
    "XTerm*cursorColor" = "#${vars.colors.Blue}";
    "XTerm*Foreground" = "#${vars.colors.White}";

    "XTerm*color0" = "#${vars.colors.Black}";
    "XTerm*color1" = "#${vars.colors.Red}";
    "XTerm*color2" = "#${vars.colors.Green}";
    "XTerm*color3" = "#${vars.colors.Yellow}";
    "XTerm*color4" = "#${vars.colors.Blue}";
    "XTerm*color5" = "#${vars.colors.Magenta}";
    "XTerm*color6" = "#${vars.colors.Cyan}";
    "XTerm*color7" = "#${vars.colors.White}";
    "XTerm*color8" = "#${vars.colors.BrightGrey}";
    "XTerm*color9" = "#${vars.colors.Red}";
    "XTerm*color10" = "#${vars.colors.Green}";
    "XTerm*color11" = "#${vars.colors.Yellow}";
    "XTerm*color12" = "#${vars.colors.Blue}";
    "XTerm*color13" = "#${vars.colors.Magenta}";
    "XTerm*color14" = "#${vars.colors.Cyan}";
    "XTerm*color15" = "#${vars.colors.DarkGreen}";
    "XTerm*color16" = "#${vars.colors.DarkYellow}";
    "XTerm*color17" = "#${vars.colors.BrightRed}";
    "XTerm*color18" = "#${vars.colors.DarkGrey}";
    "XTerm*color19" = "#${vars.colors.Grey}";
    "XTerm*color20" = "#${vars.colors.DarkWhite}";
    "XTerm*color21" = "#${vars.colors.BrightWhite}";
  };
}
