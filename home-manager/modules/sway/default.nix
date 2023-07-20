{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.sway;

  start-sway = pkgs.writeShellScriptBin "start-sway" /* sh */
    ''
      export WLR_DRM_NO_MODIFIERS=1
      dbus-launch --sh-syntax --exit-with-session ${pkgs.sway}/bin/sway
    '';
in
{
  options.pinpox.programs.sway.enable = mkEnableOption "sway window manager";

  config = mkIf cfg.enable {


    # Install these packages for my user
    home.packages = with pkgs; [
      # way-displays
      waybar
      wl-clipboard
      wlr-randr
      wofi
      start-sway
    ];

    wayland.windowManager.sway = {
      enable = true;
      config = rec{
        keybindings = lib.mkOptionDefault
          {
            "${modifier}+Return" = "exec ${pkgs.foot}/bin/foot";
            "${modifier}+p" = "exec ${pkgs.wofi}/bin/wofi --show run";


            "${modifier}+Shift+Tab" = "focus prev";
            "${modifier}+Tab" = "focus next";
          };



        # Mod1: Alt, Mod4: Win
        modifier = "Mod4";
        terminal = "${pkgs.foot}/bin/foot";

        startup = [
          { command = "${pkgs.waybar}/bin/waybar"; }
        ];

        input = {
          "*" = {
            xkb_layout = "us";
            xkb_variant = "colemak";
          };
        };

        focus = {
          wrapping = "workspace";
        };

        colors =
          let
            c = config.pinpox.colors;
          in
          {

            focused = {
              background = "#${c.Blue}";
              border = "#${c.BrightBlue}";
              childBorder = "#${c.Blue}";
              indicator = "#${c.BrightBlue}";
              text = "#${c.Black}";
            };

            focusedInactive = {
              background = "#${c.BrightWhite}";
              border = "#${c.BrightBlack}";
              childBorder = "#${c.BrightWhite}";
              indicator = "#${c.BrightBlack}";
              text = "#${c.White}";
            };

            unfocused = {
              background = "#${c.Black}";
              border = "#${c.BrightBlack}";
              childBorder = "#${c.Black}";
              indicator = "#${c.BrightBlack}";
              text = "#${c.BrightBlack}";
            };

            urgent = {
              background = "#${c.Red}";
              border = "#${c.Black}";
              childBorder = "#${c.Red}";
              indicator = "#${c.Red}";
              text = "#${c.White}";
            };

          };
        # bars = { };
        fonts = {
          names = [ "Berkeley Mono" ];
          # style = "Bold Semi-Condensed";
          size = 11.0;

        };

        workspaceAutoBackAndForth = true;
        workspaceLayout = "tabbed";

        gaps = {
          bottom = 3;
          top = 3;
          horizontal = 3;
          vertical = 3;
          inner = 3;
          left = 3;
          right = 3;
          outer = 3;
        };



        # output = {
        ##Phillips
        #DP-1 = {
        #  mode = "2560x1440@60";
        #};
        ## NZXT
        #DP-2 = {
        #  mode = "2560x1440@60";
        #};
        #};
      };
    };


  };
}
