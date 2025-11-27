{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.sway;

  start-sway =
    pkgs.writeShellScriptBin "start-sway" # sh
      ''
        export WLR_DRM_NO_MODIFIERS=1
        # dbus-launch --sh-syntax --exit-with-session ${pkgs.sway}/bin/sway
        ${pkgs.sway}/bin/sway --unsupported-gpu
      '';
in
{
  options.pinpox.programs.sway.enable = mkEnableOption "sway window manager";

  imports = [ ./swaync/default.nix ];

  config = mkIf cfg.enable (
    let
      c = config.pinpox.colors;

      # Dark theme color scheme (current)
      darkColors = ''
        client.focused #${c.BrightBlue} #${c.Blue} #${c.Black} #${c.BrightBlue} #${c.Blue}
        client.focused_inactive #${c.BrightWhite} #${c.BrightBlack} #${c.BrightWhite} #${c.BrightBlack} #${c.BrightBlack}
        client.unfocused #${c.BrightBlack} #${c.Black} #${c.BrightBlack} #${c.BrightBlack} #${c.Black}
        client.urgent #${c.BrightRed} #${c.Red} #${c.White} #${c.Red} #${c.Red}
      '';

      # Light theme color scheme (inverted contrast)
      lightColors = ''
        client.focused #${c.Blue} #${c.BrightBlue} #${c.Black} #${c.Blue} #${c.BrightBlue}
        client.focused_inactive #${c.BrightBlack} #${c.White} #${c.Black} #${c.BrightBlack} #${c.BrightBlack}
        client.unfocused #${c.White} #${c.BrightWhite} #${c.BrightBlack} #${c.White} #${c.BrightWhite}
        client.urgent #${c.Red} #${c.BrightRed} #${c.Black} #${c.Red} #${c.BrightRed}
      '';

      # Script to update Sway colors based on theme preference
      swayThemeSwitcher = pkgs.writeShellScript "sway-theme-switcher" ''
        theme="$1"

        if [[ "$theme" == "prefer-light" ]]; then
          ${pkgs.sway}/bin/swaymsg "${lightColors}"
        else
          ${pkgs.sway}/bin/swaymsg "${darkColors}"
        fi
      '';
    in
    {
      # Enable theme switcher and register Sway's theme script
      pinpox.services.theme-switcher = {
        scripts = [ "${swayThemeSwitcher}" ];
      };

      xdg.portal.config.sway = {
      # Use xdg-desktop-portal-gtk for every portal interface...
      default = [ "gtk" ];
      # ... except for the ScreenCast, Screenshot and Secret
      "org.freedesktop.impl.portal.ScreenCast" = "wlr";
      "org.freedesktop.impl.portal.Screenshot" = "wlr";
      # ignore inhibit bc gtk portal always returns as success,
      # despite sway/the wlr portal not having an implementation,
      # stopping firefox from using wayland idle-inhibit
      "org.freedesktop.impl.portal.Inhibit" = "none";
    };

    # laucher
    programs.tofi = {
      enable = true;
      settings = {
        width = "100%";
        height = "100%";
        border-width = "0";
        outline-width = "0";
        padding-left = "35%";
        padding-top = "35%";
        result-spacing = "25";
        num-results = "5";
        font = "Berkeley Mono";
        background-color = "#000A";
        prompt-text = "\"\"";
        placeholder-text = "yes?";
      };
    };

    home.packages = with pkgs; [
      wl-clipboard
      wlr-randr
      start-sway
      font-awesome
      line-awesome
    ];

    wayland.windowManager.sway = {
      enable = true;
      config = rec {

        seat = {
          "*" = {
            xcursor_theme = "${config.gtk.cursorTheme.name} ${toString config.gtk.cursorTheme.size}";
          };
        };

        keybindings = lib.mkOptionDefault {

          # Terminal
          "${modifier}+Return" = "exec rio";

          # Laucher
          "${modifier}+p" = ''
            exec ${pkgs.tofi}/bin/tofi-run --output=$(swaymsg --type get_outputs | jq '.[] | select(.focused).name') | xargs swaymsg exec --
          '';

          # Url
          "${modifier}+Shift+p" = ''
            exec ${pkgs.firefox}/bin/firefox --new-window $(cat ~/.local/share/tofi-bookmarks | ${pkgs.tofi}/bin/tofi)
          '';

          # Toggle microphone mute
          "${modifier}+m" =
            let
              mic-toggle =
                pkgs.writeShellScriptBin "mic-toggle" # sh
                  ''
                    source=$(${pkgs.pulseaudio}/bin/pactl get-default-source)
                    ${pkgs.pulseaudio}/bin/pactl set-source-mute "$source" toggle
                  '';
            in
            "exec ${mic-toggle}/bin/mic-toggle";

          # Cycle in tabbed with win+tab
          "${modifier}+Shift+Tab" = "focus prev";
          "${modifier}+Tab" = "focus next";

          # Screen lock
          "${modifier}+Shift+l" = "exec ${pkgs.swaylock}/bin/swaylock";

          # SwayNotificationCenter
          "${modifier}+n" = "exec swaync-client -t -sw";

          # Scratchpad
          "${modifier}+u" =
            ''[app_id="dropdown"] scratchpad show; [app_id="dropdown"] move position 0 0; [app_id="dropdown"] resize set width 100 ppt height 100 ppt'';

          # Screen brightness
          "XF86MonBrightnessUp" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%+";
          "XF86MonBrightnessDown" = "exec ${pkgs.brightnessctl}/bin/brightnessctl set 5%-";

          # Volume key
          "XF86AudioMute" = "exec ${pkgs.pamixer}/bin/pamixer --toggle-mute";
          "XF86AudioLowerVolume" = "exec ${pkgs.pamixer}/bin/pamixer -d 5";
          "XF86AudioRaiseVolume" = "exec ${pkgs.pamixer}/bin/pamixer -i 5";

          # Media keys
          "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
          "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
          "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";

          # "Airplane" button
          # "XF86RFKill" =

          # "Gear" button
          # "XF86AudioMedia" =

          # Screenshots
          "Print" = "exec screenshot-region";
          "Shift+Print" = "exec screenshot-region-file";

        };

        modifier = "Mod4"; # Win key
        terminal = "rio";

        startup = [
          {
            command = "swaync";
            always = true;
          }
          {
            command = "rio --app-id=dropdown";
            always = true;
          }
          { command = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator"; }
        ];

        # Application/window specific rules
        window.commands = [
          {
            command = "split horizontal, resize grow width 30 px or 30 ppt";
            criteria.class = "^Audacious$";
          }
          {
            command = "floating enable";
            criteria.title = "Firefox — Sharing Indicator";
          }
          {
            command = "floating enable";
            criteria.app_id = "dropdown";
          }
          {
            command = "move position 0 0, resize set width 100 ppt height 100 ppt";
            criteria.app_id = "dropdown";
          }
          {
            command = "move scratchpad";
            criteria.app_id = "dropdown";
          }
          {
            command = "border pixel 0";
            criteria.app_id = "dropdown";
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
          smartGaps = true;
          smartBorders  = "on";
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
        output."*".bg = "${./nixos-wallpaper.png} fill #000000";

        # swaymsg 'output DP-2 mode 2560x1440@165Hz'

        # Lenovo (Left USB-C port)
        output.DP-2.mode = "2560x1440@165Hz";

        # Phillips (Right USB-C port)
        # output.DP-1.mode = "2560x1440@60";
      };
    };
  });
}
