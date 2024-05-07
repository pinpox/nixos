{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
{

  xdg = {
    enable = true;
    configFile = {

      swaync-style = {
        target = "swaync/style.css";

        text =
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
      };

      swaync-config = {
        target = "swaync/config.json";
        # source = ./config.json;
        text = builtins.toJSON {

          # "$schema" = "/home/pinpox/.config/swaync/configSchema.json";
          "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/configSchema.json";
          "positionX" = "right";
          "positionY" = "top";
          "layer" = "overlay";
          "control-center-layer" = "top";
          "layer-shell" = true;
          "cssPriority" = "user";
          "control-center-margin-top" = 0;
          "control-center-margin-bottom" = 0;
          "control-center-margin-right" = 0;
          "control-center-margin-left" = 0;
          "notification-2fa-action" = true;
          "notification-inline-replies" = false;
          "notification-icon-size" = 64;
          "notification-body-image-height" = 100;
          "notification-body-image-width" = 200;
          "timeout" = 10;
          "timeout-low" = 5;
          "timeout-critical" = 0;
          "fit-to-screen" = true;
          "control-center-width" = 500;
          "control-center-height" = 600;
          "notification-window-width" = 500;
          "keyboard-shortcuts" = true;
          "image-visibility" = "when-available";
          "transition-time" = 200;
          "hide-on-clear" = false;
          "hide-on-action" = true;
          "script-fail-notify" = true;

          # "scripts" = {
          #   "example-script" = {
          #     "exec" = "echo 'Do something...'";
          #     "urgency" = "Normal";
          #   };
          #   "example-action-script" = {
          #     "exec" = "echo 'Do something actionable!'";
          #     "urgency" = "Normal";
          #     "run-on" = "action";
          #   };
          # };
          "notification-visibility" = {
            "example-name" = {
              "state" = "muted";
              "app-name" = "Spotify";
            };
          };
          "widgets" = [
            "menubar#label"
            "mpris"
            "backlight"
            "volume"
            "inhibitors"
            "label"
            "menubar"
            "title"
            "dnd"
            "notifications"
          ];
          "widget-config" = {
            "menubar#label" = {
              "menu#power-buttons" = {
                "label" = "";
                "position" = "right";
                "actions" = [
                  {
                    "label" = " Reboot";
                    "command" = "systemctl reboot";
                  }
                  {
                    "label" = " Lock";
                    "command" = "swaylock -f";
                  }
                  {
                    "label" = " Logout";
                    "command" = "swaymsg exit";
                  }
                  {
                    "label" = " Shut down";
                    "command" = "systemctl poweroff";
                  }
                ];
              };
              "menu#powermode-buttons" = {
                "label" = "";
                "position" = "left";
                "actions" = [
                  {
                    "label" = "Performance";
                    "command" = "powerprofilesctl set performance";
                  }
                  {
                    "label" = "Balanced";
                    "command" = "powerprofilesctl set balanced";
                  }
                  {
                    "label" = "Power-saver";
                    "command" = "powerprofilesctl set power-saver";
                  }
                ];
              };
              "buttons#topbar-buttons" = {
                "position" = "left";
                "actions" = [

                  {
                    "label" = "";
                    "command" = "~/.config/rofi/rofi-wifi-menu.sh";
                  }
                  {
                    "label" = "";
                    "command" = "~/.config/rofi/rofi-bluetooth";
                  }
                  {
                    "label" = "";
                    "command" = "screenshot-region";
                  }
                ];
              };
            };
            "backlight" = {
              "label" = "";
              "device" = "intel_backlight";
              "min" = 10;
            };
            "volume" = {
              "label" = "";
              "show-per-app" = true;
            };
            "inhibitors" = {
              "text" = "Inhibitors";
              "button-text" = "Clear All";
              "clear-all-button" = true;
            };
            "title" = {
              "text" = "Notifications";
              "clear-all-button" = true;
              "button-text" = "Clear All";
            };
            "dnd" = {
              "text" = "Do Not Disturb";
            };
            "label" = {
              "max-lines" = 5;
              "text" = "Label Text";
            };
            "mpris" = {
              "image-size" = 96;
              "image-radius" = 12;
            };
          };
        };
      };
    };
  };
}
