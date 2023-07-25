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
      font-awesome
      line-awesome
    ];




    # xdg = {
    #   enable = true;
    #   configFile = {
    #     swaync-config = {
    #       source = ./swaync/config.json;
    #       target = "swaync/config.json";
    #     };
    #   };
    # };


    # home.file."swaync-config".source = ./config.json;
    # home.file."swaync-config".target = ".config/swaync/config.json";
    # home.file."swaync-style".source = ./style.css;
    # home.file."swaync-style".target = ".config/swaync/style.css";
    # home.file."swaync-schema".source = ./configSchema.json;
    # home.file."swaync-schema".target = ".config/swaync/configSchema.json";

    wayland.windowManager.sway = {
      enable = true;
      config = rec{
        keybindings = lib.mkOptionDefault
          {
            "${modifier}+Return" = "exec ${pkgs.foot}/bin/foot";
            "${modifier}+p" = "exec ${pkgs.wofi}/bin/wofi --show run";

            # Cycle in tabbed with win+tab
            "${modifier}+Shift+Tab" = "focus prev";
            "${modifier}+Tab" = "focus next";

            # SwayNotificationCenter
            "${modifier}+n" = "exec swaync-client -t -sw";

          };

        modifier = "Mod4"; # Win key
        terminal = "${pkgs.foot}/bin/foot";

        startup = [
          { command = "swaync"; always = true; }
          { command = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator"; }
        ];



        # Application/window specific rules
        window.commands = [
          {
            command = "floating enable";
            criteria = {
              title = "Firefox — Sharing Indicator";
            };
          }
        ];

        input = {
          "*" = {
            xkb_layout = "us";
            xkb_variant = "colemak";
          };
        };

        focus.wrapping = "workspace";

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

        bars = [
          # { command = "${pkgs.waybar}/bin/waybar"; }
          { command = "waybar"; }
        ];

        fonts = {
          names = [ "Berkeley Mono" ];
          size = 11.0;
        };

        workspaceAutoBackAndForth = true;

        # Default to tabbed layout
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
