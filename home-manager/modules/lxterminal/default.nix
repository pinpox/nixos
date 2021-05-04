{ config, pkgs, lib, ... }:
let vars = import ../vars.nix;
in {

  home.packages = with pkgs; [ lxterminal ];

  # Prompt configuration
  home.file = {
    "lxterminal.conf" = {
      target = ".config/lxterminal/lxterminal.conf";
      text = ''
        [general]
        fontname=SauceCodePro Nerd Font Semi-Bold 10
        selchars=-A-Za-z0-9,./?%&#:_
        scrollback=10000
        bgcolor=#${vars.colors.Black}
        fgcolor=#${vars.colors.White}
        palette_color0=#${vars.colors.Black}
        palette_color1=#${vars.colors.Red}
        palette_color2=#${vars.colors.Green}
        palette_color3=#${vars.colors.Yellow}
        palette_color4=#${vars.colors.Blue}
        palette_color5=#${vars.colors.Magenta}
        palette_color6=#${vars.colors.Cyan}
        palette_color7=#${vars.colors.White}
        palette_color8=#${vars.colors.BrightGrey}
        palette_color9=#${vars.colors.DarkYellow}
        palette_color10=#${vars.colors.DarkGrey}
        palette_color11=#${vars.colors.Grey}
        palette_color12=#${vars.colors.DarkWhite}
        palette_color13=#${vars.colors.BrightWhite}
        palette_color14=#${vars.colors.BrightRed}
        palette_color15=#${vars.colors.DarkGreen}
        color_preset=Custom
        disallowbold=false
        cursorblinks=false
        cursorunderline=false
        audiblebell=false
        tabpos=top
        geometry_columns=100
        geometry_rows=24
        hidescrollbar=false
        hidemenubar=false
        hideclosebutton=false
        hidepointer=false
        disablef10=false
        disablealt=false
        disableconfirm=false

        [shortcut]
        new_window_accel=<Primary><Shift>n
        new_tab_accel=<Primary><Shift>t
        close_tab_accel=<Primary><Shift>w
        close_window_accel=<Primary><Shift>q
        copy_accel=<Primary><Shift>c
        paste_accel=<Primary><Shift>v
        name_tab_accel=<Primary><Shift>i
        previous_tab_accel=<Primary>Page_Up
        next_tab_accel=<Primary>Page_Down
        move_tab_left_accel=<Primary><Shift>Page_Up
        move_tab_right_accel=<Primary><Shift>Page_Down
        zoom_in_accel=<Primary><Shift>plus
        zoom_out_accel=<Primary><Shift>underscore
        zoom_reset_accel=<Primary><Shift>parenright
              '';
    };
  };
}
