{ config, pkgs, lib, ... }:
let vars = import ./vars.nix;
in {
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

    "xterm*foreground" = "#${vars.colors.White}";
    "xterm*background" = "#${vars.colors.Black}";
    "xterm*cursorColor" = "#${vars.colors.White}";
    "xterm*color0" = "#${vars.colors.Black}";
    "xterm*color1" = "#${vars.colors.Red}";
    "xterm*color2" = "#${vars.colors.Green}";
    "xterm*color3" = "#${vars.colors.Yellow}";
    "xterm*color4" = "#${vars.colors.Blue}";
    "xterm*color5" = "#${vars.colors.Magenta}";
    "xterm*color6" = "#${vars.colors.Cyan}";
    "xterm*color7" = "#${vars.colors.White}";
    "xterm*color8" = "#${vars.colors.BrightGrey}";
    "xterm*color9" = "#${vars.colors.Red}";
    "xterm*color10" = "#${vars.colors.Green}";
    "xterm*color11" = "#${vars.colors.Yellow}";
    "xterm*color12" = "#${vars.colors.Blue}";
    "xterm*color13" = "#${vars.colors.Magenta}";
    "xterm*color14" = "#${vars.colors.Cyan}";
    "xterm*color15" = "#${vars.colors.DarkGreen}";
    "xterm*color16" = "#${vars.colors.DarkYellow}";
    "xterm*color17" = "#${vars.colors.BrightRed}";
    "xterm*color18" = "#${vars.colors.DarkGrey}";
    "xterm*color19" = "#${vars.colors.Grey}";
    "xterm*color20" = "#${vars.colors.DarkWhite}";
    "xterm*color21" = "#${vars.colors.BrightWhite}";
  };
}
