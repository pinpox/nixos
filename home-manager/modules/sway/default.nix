{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.sway;

  start-sway = pkgs.writeShellScriptBin "start-sway" /* sh */
    ''
      export WLR_DRM_NO_MODIFIERS=1
      # dbus-launch --sh-syntax --exit-with-session ${pkgs.sway}/bin/sway
      ${pkgs.sway}/bin/sway
    '';
in
{
  options.pinpox.programs.sway.enable = mkEnableOption "sway window manager";

  imports = [ ./swaync/default.nix ];

  config = mkIf cfg.enable {


    # Install these packages for my user
    home.packages = with pkgs; [
      # way-displays
      (waybar.override { wireplumberSupport = false; })
      wl-clipboard
      wlr-randr
      wofi
      start-sway
      font-awesome
      line-awesome
    ];


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

            "${modifier}+u" = ''[app_id="dropdown"] scratchpad show; [app_id="dropdown"] resize set 98ppt 98ppt; [app_id="dropdown"] move position center'';

          };

        modifier = "Mod4"; # Win key
        terminal = "${pkgs.foot}/bin/foot";

        startup = [
          { command = "swaync"; always = true; }
          { command = "foot --app-id=dropdown"; always = true; }
          { command = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator"; }
        ];

        # Application/window specific rules
        window.commands = [
          {
            command = "floating enable";
            criteria.title = "Firefox — Sharing Indicator";
          }

          { command = "floating enable"; criteria.app_id = "dropdown"; }
          { command = "resize set 98ppt 98ppt"; criteria.app_id = "dropdown"; }
          { command = "move scratchpad"; criteria.app_id = "dropdown"; }
          { command = "border pixel 10"; criteria.app_id = "dropdown"; }
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

        # swaymsg 'output eDP-1 pos 0 0'
        # swaymsg 'output DP-1 pos 1920 0'
        # swaymsg 'output DP-2 pos 4480 0'

        # Set wallpaper for all screens
        # TODO: generated based on coloscheme
        output."*".bg = "~/Pictures/Wallpaper/nixos-wallpaper.png fill #000000";

        # swaymsg 'output DP-2 mode 2560x1440@165Hz'

        # Lenovo (Left USB-C port)
        output.DP-2.mode = "2560x1440@165Hz";

        # Phillips (Right USB-C port)
        # output.DP-1.mode = "2560x1440@60";
      };
    };
  };
}
