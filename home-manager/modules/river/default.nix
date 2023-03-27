{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.river;
  start-river = writeShellScript "start-river"
    ''
      export WLR_DRM_NO_MODIFIERS=1
      ${pkgs.river}/bin/river
    '';

  screenshot-region = writeShellScript "screenshot-region"
    ''
      ${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png
    '';

in
{
  options.pinpox.programs.river.enable = mkEnableOption "river window manager";

  config = mkIf cfg.enable {

    # Install these packages for my user
    home.packages = with pkgs; [
      river
      start-river
      screenshot-region
    ];

    xdg = {
      enable = true;
      configFile = {

        # River configuration files
        river-config = {
          target = "river/init";
          source = ./river-config;
          executable = true;
        };

        river-config-extra = {
          target = "river/init_exta";
          text = ''
            # riverctl map normal Super F12 spawn '${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png'
            # riverctl map normal Super F12 spawn ${screenshot-region}
            riverctl map normal Super p spawn "${pkgs.wofi}/bin/wofi --show run"
            ${pkgs.waybar}/bin/waybar
            # ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 1920x1080 --pos 0,0 \
            # --output DP-1 --mode 2560x1440 --pos 4480,0 \
            # --output DP-2 --mode 2560x1440@164.54 --pos 1920,0

            # wlr-randr --output eDP-1 --on --mode 1920x1080 --pos 0,0 --output DP-1  --on --mode 2560x1440 --pos 4480,0 --output DP-2  --on --mode 2560x1440  --pos 1920,0
          '';
          executable = true;
        };

        # river-luatile layouts

        luatile-layout = {
          target = "river-luatile/layout.lua";
          source = ./layout.lua;
        };

        luatile-json = {
          target = "river-luatile/json.lua";
          source = ./json.lua;
        };


      };
    };

    programs.waybar = {
      enable = true;
      style = ./style.css;
      settings.mainbar = {
        layer = "top";
        position = "top";
        height = 30;

        spacing = 4; # Gaps between modules (4px)
        modules-left = [ "river/tags" ];
        # modules-center = ["river/mode", "river/window"],
        # modules-right = ["idle_inhibitor", "pulseaudio", "network", "backlight", "battery", "cpu","memory", "temperature", "clock", "tray"],
        modules-right = [ "tray" "network" "pulseaudio" "battery" "clock" ];

        "river/tags" = {
          "num-tags" = 9;
        };

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
          format-icons = [ " " " " " " " " " " ];
        };
        network = {
          format-wifi = "{essid} ({signalStrength}%)  ";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
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
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };
      };
    };
  };
}
