{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.waybar;
in
{
  options.pinpox.programs.waybar.enable = mkEnableOption "waybar configuration";

  config = mkIf cfg.enable {

    # home.packages = with pkgs; [ waybar];

    programs.waybar = {

      package = pkgs.waybar.override { wireplumberSupport = false; };

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

        modules-center = [ "mpris" ];

        modules-right = [
          "tray"
          "custom/notification"
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
        };

        # "river/tags" = {
        #   "num-tags" = 9;
        # };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = " ";
            deactivated = " ";
          };
        };

        tray = {
          # "icon-size": 21,
          spacing = 10;
        };
        clock = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };
        #    "cpu": {
        #        "format": "{usage}% ",
        #        "tooltip": false
        #    },
        #    "memory": {
        #        "format": "{}% "
        #    },
        #    "temperature": {
        #        // "thermal-zone": 2,
        #        // "hwmon-path": "/sys/class/hwmon/hwmon2/temp1_input",
        #        "critical-threshold": 80,
        #        // "format-critical": "{temperatureC}°C {icon}",
        #        "format": "{temperatureC}°C {icon}",
        #        "format-icons": ["", "", ""]
        #    },
        #    "backlight": {
        #        // "device": "acpi_video1",
        #        "format": "{percent}% {icon}",
        #        "format-icons": [""]
        #    },
        battery = {
          states = {
            good = 95;
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
          format-good = "{capacity}% {icon}";
          format-full = "{capacity}% {icon}";
          format-icons = [
            " "
            " "
            " "
            " "
            " "
          ];
        };
        network = {
          format-wifi = "{essid} ({signalStrength}%)  ";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };
        "custom/notification" = {
          "tooltip" = false;
          "format" = "{} {icon}";
          "format-icons" = {
            "notification" = "<span foreground='red'><sup></sup></span>";
            "none" = "";
            "dnd-notification" = "<span foreground='red'><sup></sup></span>";
            "dnd-none" = "";
            "inhibited-notification" = "<span foreground='red'><sup></sup></span>";
            "inhibited-none" = "";
            "dnd-inhibited-notification" = "<span foreground='red'><sup></sup></span>";
            "dnd-inhibited-none" = "";
          };
          "return-type" = "json";
          "exec-if" = "which swaync-client";
          "exec" = "swaync-client -swb";
          "on-click" = "swaync-client -t -sw";
          "on-click-right" = "swaync-client -d -sw";
          "escape" = true;
        };
        pulseaudio = {
          scroll-step = 1; # %, can be a float
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = "ﱝ {icon} {format_source}";
          format-muted = "ﱝ {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = "pavucontrol";
        };
      };
    };
  };
}
