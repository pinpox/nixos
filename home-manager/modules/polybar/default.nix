{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.polybar;
in
{
  options.pinpox.programs.polybar.enable = mkEnableOption "polybar";

  config = mkIf cfg.enable {

    services.polybar = {
      enable = true;
      package = pkgs.polybar.override {
        i3GapsSupport = true;
        pulseSupport = true;
        # alsaSupport = true;
        # iwSupport = true;
        # githubSupport = true;
      };
      # script = ''/home/pinpox/start-polybar.sh '';
      script = ''
        #!/bin/sh
        PATH=/run/current-system/sw/bin/:/home/pinpox/.nix-profile/bin/
        export DISPLAY=:0

        killall ".polybar-wrappe" || echo "Polybar was not running"

        echo "Outputs:"
        polybar -m

        for i in $(polybar -m | awk -F: '{print $1}'); do
          echo "Starting Polybar on monitor $"
          MONITOR=$i polybar primary -c ~/.config/polybar/config -r &
        done
      '';

      # Lookup icons with:
      # https://www.nerdconfig.pinpox.fonts.com/cheat-sheet
      # Then copy by hex code from:
      # https://mathew-kurian.github.io/CharacterMap/

      config = {
        "bar/primary" = {
          monitor = "\${env:MONITOR:Virtual1}";
          bottom = true;

          width = "100%";
          height = 22;
          radius = 0;

          background = "#${config.pinpox.colors.Black}";
          foreground = "#${config.pinpox.colors.White}";

          line-size = 0;
          border-size = 0;
          border-color = "#00000000";
          module-margin-left = 2;
          module-margin-right = 2;

          font-0 =
            "${config.pinpox.font.normal.family}:style=${config.pinpox.font.normal.style}:pixelsize=8";

          modules-left = "i3";
          modules-center = "music";
          modules-right = "filesystem pulseaudio eth memory cpu date";
          # Disabled modules: pkg

          tray-position = "right";
          tray-padding = 2;
          tray-background = "#${config.pinpox.colors.Blue}";
        };

        "module/filesystem" = {

          format-mounted-prefix-foreground = "#${config.pinpox.colors.Blue}";
          format-unmounted-prefix-foreground = "#${config.pinpox.colors.Blue}";
          label-unmounted-foreground = "#${config.pinpox.colors.White}";

          format-mounted-prefix-padding-right = 1;
          format-unmounted-prefix-padding-right = 1;

          interval = 25;
          mount-0 = "/";
          type = "internal/fs";
          format-mounted-prefix = "";
          # format-mounted-prefix-padding = 1;
          # format-mounted-padding   = 2;
          # format-unmounted-padding = 2;
          label-mounted = "%percentage_used%% [%free%]";
          label-unmounted = "%mountpoint% not mounted";
        };

        "module/i3" = {

          type = "internal/i3";
          format = "<label-state> <label-mode>";
          index-sort = true;
          wrapping-scroll = false;

          # Only show workspaces on the same output as the bar
          pin-workspaces = true;
          # label-mode-padding           = 2;
          label-mode-background = "#${config.pinpox.colors.White}";

          # focused                    = Active workspace on focused monitor
          label-focused = "%name%";
          label-focused-background = "#${config.pinpox.colors.Blue}";
          label-focused-foreground = "#${config.pinpox.colors.Black}";
          label-focused-padding = 2;

          # unfocused                  = Inactive workspace on any monitor
          label-unfocused = "%name%";
          label-unfocused-background = "${config.pinpox.colors.BrightBlack}";
          label-unfocused-padding = 2;

          # visible                    = Active workspace on unfocused monitor
          label-visible = "%name%";
          label-visible-background = "#${config.pinpox.colors.BrightBlack}";
          label-visible-padding = 2;

          # urgent                     = Workspace with urgency hint set
          label-urgent = "%name%";
          label-urgent-background = "#${config.pinpox.colors.Red}";
          label-urgent-padding = 2;

        };

        "module/cpu" = {
          type = "internal/cpu";
          interval = 2;
          format-prefix-padding-right = 1;
          format-prefix = "";
          format-prefix-foreground = "#${config.pinpox.colors.Blue}";
          label = "%percentage%%";
          # format-padding = 2;
        };

        "module/memory" = {
          type = "internal/memory";
          interval = 2;
          format-prefix = "";

          format-prefix-padding-right = 1;
          format-prefix-foreground = "#${config.pinpox.colors.Blue}";
          label = "%percentage_used%%";
          # format-padding = 2;
        };

        "module/wlan" = {
          type = "internal/network";
          interface = "wlan0";
          interval = 3;

          # format-connected-padding = 2;
          # format-disconnected-padding = 2;

          format-connected = "<ramp-signal> <label-connected>";
          # format-connected-background = ${colors.color-8}
          label-connected = "%signal%% %essid%";

          format-disconnected = "";
          # ; format-disconnected = <label-disconnected>
          # ;label-disconnected = %ifname% disconnected
          # label-disconnected-foreground = ${colors.foreground}

          ramp-signal-0 = "";
          # ramp-signal-foreground = ${colors.prefix-color}
        };

        "module/eth" = {
          type = "internal/network";
          interface = "eno1"; # TODO automate interface name setting
          interval = 3;

          format-connected-prefix-padding-right = 1;
          format-connected-prefix = "";
          format-connected-prefix-foreground = "#${config.pinpox.colors.Blue}";
          label-connected = "%local_ip%";
          # format-connected-prefix-padding = 1;

          format-disconnected = "";
          # ;format-disconnected = "<label-disconnected>";
          # ;label-disconnected = "%ifname% disconnected";
          # ;label-disconnected-foreground = ${colors.foreground}
        };

        "module/date" = {

          format-prefix-foreground = "#${config.pinpox.colors.Black}";
          format-foreground = "#${config.pinpox.colors.Black}";
          format-background = "#${config.pinpox.colors.Blue}";

          type = "internal/date";
          interval = 5;

          date = "";
          date-alt = " %Y-%m-%d";

          time = "%H:%M  ";
          time-alt = "%H:%M:%S  ";

          format-prefix = "";
          format-prefix-padding-right = 1;
          format-prefix-padding-left = 1;

          label = "%date% %time%";
        };

        "module/pulseaudio" = {
          type = "internal/pulseaudio";

          # ; Sink to be used, if it exists (find using `pacmd list-sinks`, name field)
          # ; If not, uses default sink
          # sink = alsa_output.pci-0000_12_00.3.analog-stereo
          # ; Use PA_VOLUME_UI_MAX (~153%) if true, or PA_VOLUME_NORM (100%) if false
          use-ui-max = false;

          interval = 5;

          # label-muted-foreground = #666
          ramp-volume-foreground = "#${config.pinpox.colors.Blue}";
          format-volume-prefix-foreground = "#${config.pinpox.colors.Blue}";

          label-muted = "  0%";
          ramp-volume-0 = "";
          ramp-volume-1 = "";
          ramp-volume-2 = "";
          format-volume = "<ramp-volume> <label-volume>";
          format-muted = "<label-muted>";
          label-volume = "%percentage%%";

          click-right = "pavucontrol &";
        };

        "module/music" = {
          type = "custom/script";
          interval = 2;

          label = "%output:0:45:...%";
          exec = "~/.config/polybar/mpris.sh";
          click-left = "playerctl play-pause";
          click-right = "playerctl next";
        };
      };
    };
  };
}
