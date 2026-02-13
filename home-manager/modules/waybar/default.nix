{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.waybar;

  # source=$(${pkgs.pulseaudio}/bin/pactl get-default-source)
  # writeShellApplication {
  #   name = "show-nixos-org";
  #
  #   runtimeInputs = [
  #     curl
  #     w3m
  #   ];
  #
  #   text = ''
  #     curl -s 'https://nixos.org' | w3m -dump -T text/html
  #   '';
  # }

  mic-exec-if =
    # Returns 0 if mic is not muted and there are clients listening,
    # 1 otherwise.
    pkgs.writeShellScriptBin "mic-exec-if" # sh
      ''
        source=$(${pkgs.pulseaudio}/bin/pactl get-default-source)
        mute_state=$(${pkgs.pulseaudio}/bin/pactl get-source-mute "$source" | awk '{print $2}')

        if [ "$mute_state" = "yes" ]; then
          exit 1
        fi

        clients=$(${pkgs.pulseaudio}/bin/pactl list source-outputs | grep "application\.name" | uniq | awk -F'"' '{print $2}' | tr '\n' ',' | sed 's/,$/\n/')
        if [ -n "$clients" ]; then
          exit 0
        fi

        exit 1
      '';

  mic-toggle =
    # Toggle microphone on/off
    pkgs.writeShellScriptBin "mic-toggle" # sh
      ''
        source=$(${pkgs.pulseaudio}/bin/pactl get-default-source)
        ${pkgs.pulseaudio}/bin/pactl set-source-mute "$source" toggle
      '';

  mic-status-apps =
    # List applications currently accessing the microphone
    pkgs.writeShellScriptBin "mic-status-apps" # sh
      ''
        # List all input streams
        clients=$(${pkgs.pulseaudio}/bin/pactl list source-outputs | grep "application\.name" | uniq | awk -F'"' '{print $2}' | tr '\n' ',' | sed 's/,$/\n/')

        # Remove duplicates and format
        if [ -n "$clients" ]; then
            unique_clients=$(echo "$clients" | sort | uniq | paste -sd, -)
            echo " $unique_clients"
        fi
      '';
in
{
  options.pinpox.programs.waybar.enable = mkEnableOption "waybar configuration";

  config = mkIf cfg.enable {

    programs.waybar = {

      enable = true;

      style =
        let
          c = config.pinpox.colors;
        in
        ''

            @define-color Black #${c.Black};
            @define-color BrightBlack #${c.BrightBlack};
            @define-color White #${c.White};
            @define-color BrightWhite #${c.BrightWhite};
            @define-color Yellow #${c.Yellow};
            @define-color BrightYellow #${c.BrightYellow};
            @define-color Green #${c.Green};
            @define-color BrightGreen #${c.BrightGreen};
            @define-color Cyan #${c.Cyan};
            @define-color BrightCyan #${c.BrightCyan};
            @define-color Blue #${c.Blue};
            @define-color BrightBlue #${c.BrightBlue};
            @define-color Magenta #${c.Magenta};
            @define-color BrightMagenta #${c.BrightMagenta};
            @define-color Red #${c.Red};
            @define-color BrightRed #${c.BrightRed};

          ${fileContents ./style.css}
        '';

      settings.mainbar = {
        layer = "top";
        position = "bottom";
        # height = 20;

        spacing = 4; # Gaps between modules (4px)
        modules-left = [

          "sway/workspaces"
          "sway/mode"

          # "river/tags"
        ];
        # modules-center = ["river/mode", "river/window"],
        # modules-right = ["idle_inhibitor", "backlight",  "cpu","memory", "temperature"],

        modules-center = [
          "custom/mic"
          "mpris"
        ];

        modules-right = [
          "tray"
          "network"
          "pulseaudio"
          "battery"
          "clock"
        ];

        mpris = {
          player-icons = {
            "default" = "🎵";
            "strawberry" = "🍓";
          };
          format = "{player_icon} {artist} - {title}";
          max-length = 40;
          ignored-players = [
            "firefox"
            "chromium"
          ];
        };

        # "river/tags" = {
        #   "num-tags" = 9;
        # };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = " ";
            deactivated = " ";
          };
        };

        tray = {
          # "icon-size": 21,
          spacing = 10;
        };
        clock = {
          format = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        #    "cpu": {
        #        "format": "{usage}% ",
        #        "tooltip": false
        #    },
        #    "memory": {
        #        "format": "{}% "
        #    },
        #    "temperature": {
        #        // "thermal-zone": 2,
        #        // "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
        #        "critical-threshold": 80,
        #        // "format-critical": "{temperatureC}°C {icon}",
        #        "format": "{temperatureC}°C {icon}",
        #        "format-icons": ["", "", ""]
        #    },
        #    "backlight": {
        #        // "device": "acpi_video1",
        #        "format": "{percent}% {icon}",
        #        "format-icons": [""]
        #    },
        battery = {
          states = {
            good = 95;
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% ▼";
          format-charging = "{capacity}% ▲";
          format-plugged = "{capacity}% ▲";
          format-alt = "{time}";
          format-full = "{capacity}% ▲";
        };
        network = {
          format-wifi = "{essid} ({signalStrength}%)";
          format-ethernet = "{ipaddr}/{cidr}";
          tooltip-format = "{ifname} via {gwaddr}";
          format-linked = "{ifname} (No IP)";
          format-disconnected = "Disconnected ✕";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };


        pulseaudio = {
          "markup" = true;
          scroll-step = 1; # %, can be a float
          format = "{volume}% <span color='#${config.pinpox.colors.Green}' rise='2000'>•</span> {format_source}";
          format-bluetooth = "{volume}% <span color='#${config.pinpox.colors.Green}' rise='2000'>•</span> {format_source}";
          format-bluetooth-muted = "✕ <span color='#${config.pinpox.colors.Green}' rise='2000'>•</span> {format_source}";
          format-muted = "<span color='#${config.pinpox.colors.Red}'>{volume}%</span> <span color='#${config.pinpox.colors.Green}' rise='2000'>•</span> {format_source}";
          format-source = "{volume}% <span color='#${config.pinpox.colors.Red}' rise='2000'>•</span>";
          format-source-muted = "<span color='#${config.pinpox.colors.Red}'>{volume}%</span> <span color='#${config.pinpox.colors.Red}' rise='2000'>•</span>";

          "on-click" = "${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
          "on-click-right" = "${mic-toggle}/bin/mic-toggle";
        };

        "custom/mic" = {
          "format" = "{}";
          "tooltip" = false;
          "interval" = 1;
          "exec" = "${mic-status-apps}/bin/mic-status-apps";
          "exec-if" = "${mic-exec-if}/bin/mic-exec-if";
          "on-click" = "${mic-toggle}/bin/mic-toggle";
        };
      };
    };
  };
}
