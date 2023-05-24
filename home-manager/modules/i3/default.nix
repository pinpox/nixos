{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.i3;
in
{
  options.pinpox.programs.i3.enable = mkEnableOption "i3 window manager";

  config = mkIf cfg.enable {

    xsession.scriptPath = ".hm-xsession";
    xsession.enable = true;

    xsession.windowManager.i3 = {
      enable = true;

      package = pkgs.i3-gaps;
      config = {
        menu = "rofi";
        window.commands = [{
          command = "border pixel 2";
          criteria = { class = "^.*"; };
        }];
        startup = [
          # TODO: probably we can restart polybar like this
          # {
          # command = "systemctl --user restart polybar.service";
          # always = true;
          # notification = false;
          # }
          {
            command = ''
              cbatticon --icon-type standard --low-level 20 --critical-level 10 -u 30 --command-critical-level "notify-send -i battery -u critical 'battery low'" '';
            always = false;
            notification = false;
          }
          {
            command = "xfce4-volumed-pulse &";
            always = false;
            notification = false;
          }
          {
            command = "nitrogen --restore";
            always = true;
            notification = false;
          }
          {
            command = "pkill -USR1 polybar";
            always = true;
            notification = false;
          }
        ];
        colors = {
          background = "#${config.pinpox.colors.Black}";
          focused = {
            background = "#${config.pinpox.colors.Blue}";
            border = "#${config.pinpox.colors.Blue}";
            childBorder = "#${config.pinpox.colors.Blue}";
            indicator = "#${config.pinpox.colors.Blue}";
            text = "#${config.pinpox.colors.Black}";
          };

          focusedInactive = {
            background = "#${config.pinpox.colors.BrightBlack}";
            border = "#${config.pinpox.colors.BrightBlack}";
            childBorder = "#${config.pinpox.colors.BrightBlack}";
            indicator = "#${config.pinpox.colors.Black}";
            text = "#${config.pinpox.colors.Black}";
          };

          unfocused = {
            background = "#${config.pinpox.colors.Black}";
            border = "#${config.pinpox.colors.BrightBlack}";
            childBorder = "#${config.pinpox.colors.BrightBlack}";
            indicator = "#${config.pinpox.colors.Black}";
            text = "#${config.pinpox.colors.Blue}";
          };

          urgent = {
            background = "#${config.pinpox.colors.Red}";
            border = "#${config.pinpox.colors.Red}";
            childBorder = "#${config.pinpox.colors.Red}";
            indicator = "#${config.pinpox.colors.Red}";
            text = "#${config.pinpox.colors.Black}";
          };
        };

        floating = { border = 2; };

        focus = {
          followMouse = true;
          forceWrapping = true;
        };

        config.pinpox.font = [
          "${config.pinpox.font.normal.family} ${config.pinpox.font.normal.style} ${
          toString config.pinpox.font.size
        }px"
        ];

        bars = [ ];

        gaps = {
          bottom = 5;
          horizontal = 5;
          inner = 5;
          left = 5;
          outer = 5;
          right = 5;
          top = 5;
          vertical = 5;
          smartBorders = "no_gaps";
          smartGaps = true;
        };
        modifier = "Mod4";
        keybindings =
          let modifier = config.xsession.windowManager.i3.config.modifier;
          in
          lib.mkOptionDefault {

            "${modifier}+Shift+Escape" = "exec xkill";
            "${modifier}+p" =
              "exec ${pkgs.rofi}/bin/rofi -show run -lines 7 -eh 1 -bw 0  -fullscreen -padding 200";
            "${modifier}+Shift+p" =
              "exec ${pkgs.rofi-pass} -show combi -lines 7 -eh 3 -bw 0 -matching fuzzy";
            "${modifier}+Shift+x" = "exec xscreensaver-command -lock";
            "${modifier}+Shift+Tab" = "workspace prev";
            "${modifier}+Tab" = "workspace next";
            "XF86AudioLowerVolume" =
              "exec --no-startup-id pactl set-sink-volume 0 -5%"; # decrease sound volume
            "XF86AudioMute" =
              "exec --no-startup-id pactl set-sink-mute 0 toggle"; # mute sound
            "XF86AudioNext" = "exec playerctl next";
            "XF86AudioPlay" = "exec playerctl play-pause";
            "XF86AudioPrev" = "exec playerctl previous";
            "XF86AudioRaiseVolume" =
              "exec --no-startup-id pactl set-sink-volume 0 +5% #increase sound volume";
            "XF86AudioStop" = "exec playerctl stop";
            "XF86MonBrightnessDown" =
              "exec xbacklight -dec 20"; # decrease screen brightness
            "XF86MonBrightnessUp" =
              "exec xbacklight -inc 20"; # increase screen brightness
            "Print" =
              "exec import png:- | xclip -selection clipboard -t image/png";
          };

        terminal = "alacritty";

        # window = "TODO"
        workspaceLayout = "tabbed";

      };
    };
  };
}
