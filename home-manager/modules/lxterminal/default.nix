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
        bgcolor=#${vars.colors.base00}
        fgcolor=#${vars.colors.base05}
        palette_color0=#${vars.colors.base00}
        palette_color1=#${vars.colors.base08}
        palette_color2=#${vars.colors.base0B}
        palette_color3=#${vars.colors.base0A}
        palette_color4=#${vars.colors.base0D}
        palette_color5=#${vars.colors.base0E}
        palette_color6=#${vars.colors.base0C}
        palette_color7=#${vars.colors.base05}
        palette_color8=#${vars.colors.base03}
        palette_color9=#${vars.colors.base09}
        palette_color10=#${vars.colors.base01}
        palette_color11=#${vars.colors.base02}
        palette_color12=#${vars.colors.base04}
        palette_color13=#${vars.colors.base06}
        palette_color14=#${vars.colors.base0F}
        palette_color15=#${vars.colors.base07}
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
