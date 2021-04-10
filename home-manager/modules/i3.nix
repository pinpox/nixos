{ config, pkgs, lib, ... }:
let vars = import ./vars.nix;
in {

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
        {
          command = "autorandr -c";
          always =
            false; # Important, run only on first start (will loop otherwise)!
          notification = false;
        }
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
        background = "#${vars.colors.base00}";
        focused = {
          background = "#${vars.colors.base0D}";
          border = "#${vars.colors.base0D}";
          childBorder = "#${vars.colors.base0D}";
          indicator = "#${vars.colors.base0D}";
          text = "#${vars.colors.base00}";
        };

        focusedInactive = {
          background = "#${vars.colors.base03}";
          border = "#${vars.colors.base03}";
          childBorder = "#${vars.colors.base03}";
          indicator = "#${vars.colors.base00}";
          text = "#${vars.colors.base00}";
        };

        unfocused = {
          background = "#${vars.colors.base00}";
          border = "#${vars.colors.base03}";
          childBorder = "#${vars.colors.base03}";
          indicator = "#${vars.colors.base00}";
          text = "#${vars.colors.base0D}";
        };

        urgent = {
          background = "#${vars.colors.base08}";
          border = "#${vars.colors.base08}";
          childBorder = "#${vars.colors.base08}";
          indicator = "#${vars.colors.base08}";
          text = "#${vars.colors.base00}";
        };
      };

      floating = { border = 2; };

      focus = {
        followMouse = true;
        forceWrapping = true;
      };

      fonts = [
        "${vars.font.normal.family} ${vars.font.normal.style} ${
          toString vars.font.size
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
        in lib.mkOptionDefault {

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
}
