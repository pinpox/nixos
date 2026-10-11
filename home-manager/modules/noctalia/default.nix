{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.noctalia;
  c = config.pinpox.colors;

  # Plugin path source (one subdirectory per plugin). Read-only for noctalia;
  # updates arrive by rebuilding. `noctalia plugins lint` cross-checks each
  # manifest's declared settings against the Luau entries at build time.
  plugins = pkgs.runCommand "noctalia-plugins" { nativeBuildInputs = [ pkgs.noctalia ]; } ''
    cp -r ${./plugins} $out
    chmod -R u+w $out
    substituteInPlace $out/firefox-history/history.luau \
      --replace-fail '@python3@' '${lib.getExe pkgs.python3}'
    noctalia plugins lint $out/askpass $out/himalaya-mail $out/firefox-history
  '';

  terminalColors = {
    normal = {
      black = "#${c.Black}";
      red = "#${c.Red}";
      green = "#${c.Green}";
      yellow = "#${c.Yellow}";
      blue = "#${c.Blue}";
      magenta = "#${c.Magenta}";
      cyan = "#${c.Cyan}";
      white = "#${c.White}";
    };
    bright = {
      black = "#${c.BrightBlack}";
      red = "#${c.BrightRed}";
      green = "#${c.BrightGreen}";
      yellow = "#${c.BrightYellow}";
      blue = "#${c.BrightBlue}";
      magenta = "#${c.BrightMagenta}";
      cyan = "#${c.BrightCyan}";
      white = "#${c.BrightWhite}";
    };
  };

  # Custom palette "pinpox", both variants derived from the shared
  # pinpox.colors palette (selected by theme.custom_palette below).
  palette = {
    dark = {
      mPrimary = "#${c.Blue}";
      mOnPrimary = "#${c.Black}";
      mSecondary = "#${c.Black}";
      mOnSecondary = "#${c.White}";
      mTertiary = "#${c.Green}";
      mOnTertiary = "#${c.Black}";
      mError = "#${c.Red}";
      mOnError = "#${c.White}";
      mSurface = "#${c.Black}";
      mOnSurface = "#${c.White}";
      mHover = "#${c.BrightBlack}";
      mOnHover = "#${c.White}";
      mSurfaceVariant = "#${c.Black}";
      mOnSurfaceVariant = "#${c.BrightBlue}";
      mOutline = "#${c.BrightBlack}";
      mShadow = "#${c.Black}";
      terminal = terminalColors // {
        background = "#${c.Black}";
        foreground = "#${c.White}";
        cursor = "#${c.White}";
        cursorText = "#${c.Black}";
        selectionBg = "#${c.Blue}";
        selectionFg = "#${c.Black}";
      };
    };
    light = {
      mPrimary = "#${c.Blue}";
      mOnPrimary = "#${c.BrightWhite}";
      mSecondary = "#${c.Cyan}";
      mOnSecondary = "#${c.BrightWhite}";
      mTertiary = "#${c.Green}";
      mOnTertiary = "#${c.BrightWhite}";
      mError = "#${c.Red}";
      mOnError = "#${c.BrightWhite}";
      mSurface = "#${c.BrightWhite}";
      mOnSurface = "#${c.Black}";
      mHover = "#${c.White}";
      mOnHover = "#${c.Black}";
      mSurfaceVariant = "#${c.White}";
      mOnSurfaceVariant = "#${c.Blue}";
      mOutline = "#${c.White}";
      mShadow = "#${c.White}";
      terminal = terminalColors // {
        background = "#${c.BrightWhite}";
        foreground = "#${c.Black}";
        cursor = "#${c.Black}";
        cursorText = "#${c.BrightWhite}";
        selectionBg = "#${c.Blue}";
        selectionFg = "#${c.BrightWhite}";
      };
    };
  };

  # Session menu; every entry counts down 10 s before acting.
  sessionAction =
    shortcut: attrs:
    {
      inherit shortcut;
      countdown_seconds = 10;
    }
    // attrs;
in
{
  options.pinpox.programs.noctalia.enable = mkEnableOption "noctalia desktop shell";

  # Config for noctalia v5 (native shell, config.toml). home-manager's
  # programs.noctalia renders `settings` to ~/.config/noctalia/config.toml
  # (validated at build with `noctalia config validate`) and the palette to
  # palettes/pinpox.json, and runs the shell as a user service bound to the
  # graphical session. Runtime changes made in the settings UI land in
  # ~/.local/state/noctalia/settings.toml and override this file; delete that
  # file to get back to the declared state.
  config = mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      systemd.enable = true;
      customPalettes.pinpox = palette;

      settings = {
        # v4 rendered every non-bar surface with fontDefaultScale 1.24; the
        # bar gets the same via bar.main.font_scale.
        accessibility.ui_scale = 1.24;
        shell = {
          font_family = config.pinpox.font.normal.family;
          # v4 ran with every radius ratio at 0: square bar, capsules, panels.
          corner_radius_scale = 0.0;
          settings_show_advanced = true;
          # Clipboard history stays off (no cliphist-style persistence).
          clipboard_enabled = false;
          animation.enabled = false;
          # Launcher/dock apps as transient user units (systemd-run) instead of
          # children of noctalia.service: a shell restart (config change, IPC
          # loss) must not take Firefox & co. down with it (KillMode=control-group).
          launch_apps_as_systemd_services = true;
          # rnnoise's virtual source is not a real capture.
          privacy.mic_filter_regex = "rnnoise";
          # Attached panels inherit the bar's (transparent) background, so
          # every panel floats; the control center still opens at its button.
          panel = {
            shadow = false;
            borders = false;
            launcher_placement = "floating";
            launcher_position = "center";
            control_center_placement = "floating";
            open_near_click_control_center = true;
            session_placement = "floating";
          };
          launcher = {
            categories = true;
            show_icons = true;
            sort_by_usage = true;
            app_grid = false;
          };
          session = {
            show_shortcuts = true;
            actions = [
              (sessionAction "1" { action = "lock"; })
              (sessionAction "2" { action = "lock_and_suspend"; })
              (sessionAction "3" {
                action = "command";
                label = "Hibernate";
                glyph = "moon";
                command = "systemctl hibernate";
              })
              (sessionAction "4" { action = "reboot"; })
              (sessionAction "5" { action = "logout"; })
              (sessionAction "6" {
                action = "shutdown";
                variant = "destructive";
              })
              (sessionAction "7" {
                action = "command";
                label = "Reboot to UEFI";
                glyph = "cpu";
                command = "systemctl reboot --firmware-setup";
              })
            ];
          };
        };

        # wl-harmonograph draws the background (sway module).
        wallpaper.enabled = false;

        theme = {
          mode = "dark";
          source = "custom";
          custom_palette = "pinpox";
          templates = {
            enable_builtin_templates = false;
            enable_community_templates = false;
          };
        };

        notification.layer = "overlay";
        osd.position = "top_right";

        lockscreen = {
          enabled = true;
          # Also covers lid close / systemctl suspend via logind PrepareForSleep,
          # and `loginctl lock-session`; no swayidle needed for those.
          lock_before_suspend = true;
          fingerprint = false;
        };
        idle.behavior.lock = {
          timeout = 300;
          action = "lock";
          enabled = true;
        };

        location = {
          auto_locate = false;
          address = "Cologne";
        };
        weather.enabled = false;
        nightlight.enabled = false;

        control_center.shortcuts = [
          { type = "wifi"; }
          { type = "bluetooth"; }
          { type = "wallpaper"; }
          { type = "notification"; }
          { type = "power_profile"; }
          { type = "caffeine"; }
          { type = "nightlight"; }
        ];

        bar.main = {
          position = "bottom";
          thickness = 36;
          background_opacity = 0.0;
          shadow = false;
          radius = 0;
          margin_ends = 4;
          margin_edge = 4;
          padding = 2;
          widget_spacing = 6;
          font_scale = 1.24;
          capsule = true;
          capsule_radius = 0.0;
          start = [
            "workspaces"
            "media"
          ];
          center = [ ];
          end = [
            "tray"
            "bluetooth"
            "network"
            "notifications"
            "battery"
            "volume"
            "microphone"
            "privacy"
            "brightness"
            "mail"
            "clock"
          ];
        };

        widget = {
          workspaces = {
            style = "regular";
            label_source = "id";
            max_label_chars = 2;
            focused_color = "primary";
            occupied_color = "secondary";
          };
          media = {
            artist_first = true;
            max_length = 200;
            title_scroll = "on_hover";
            hide_when_no_media = true;
          };
          tray.hide_passive = false;
          bluetooth.show_label = false;
          network.show_label = true;
          battery = {
            display_mode = "graphic";
            show_label = false;
          };
          volume = {
            show_label = true;
            icon_color = "tertiary";
          };
          microphone = {
            type = "volume";
            device = "input";
            show_label = true;
            icon_color = "error";
          };
          privacy.hide_inactive = true;
          brightness.show_label = false;
          mail.type = "pinpox/himalaya-mail:unread";
          clock = {
            format = "{:%Y-%m-%d %H:%M}";
            tooltip_format = "{:%H:%M %a, %b %d}";
          };
        };

        plugins = {
          enabled = [
            "pinpox/askpass"
            "pinpox/himalaya-mail"
            "pinpox/firefox-history"
          ];
          auto_update = "none";
          source = [
            {
              name = "pinpox";
              kind = "path";
              location = "${plugins}";
              enabled = true;
            }
            # The built-in git sources would be cloned on first use; keep them
            # off so the shell never fetches plugins on its own.
            {
              name = "official";
              kind = "git";
              location = "https://github.com/noctalia-dev/official-plugins";
              enabled = false;
            }
            {
              name = "community";
              kind = "git";
              location = "https://github.com/noctalia-dev/community-plugins";
              enabled = false;
            }
          ];
        };
      };
    };

    # The HM unit restarts on config/palette changes; plugin code changes
    # only show up in the unit through the plugins store path.
    systemd.user.services.noctalia.Unit.X-Restart-Triggers = [ "${plugins}" ];

    # noctalia 5.2.1's sway backend never reconnects after sway drops its IPC
    # client (sway disconnects clients with >4 MB unread output). The process
    # stays alive with empty workspaces, so Restart= never fires; restart it
    # when the disconnect is logged. Drop once upstream reconnects on sway.
    # Ordered after the target, not noctalia.service: WantedBy makes the target
    # order after us, and noctalia is After= the target, which forms a cycle
    # that systemd breaks by dropping this unit's start job.
    systemd.user.services.noctalia-sway-watchdog = {
      Unit = {
        Description = "Restart noctalia when it loses the sway IPC connection";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = lib.getExe (
          pkgs.writeShellApplication {
            name = "noctalia-sway-watchdog";
            runtimeInputs = [ pkgs.systemd ];
            text = ''
              journalctl --user --unit noctalia.service --follow --lines 0 --output cat \
                | while read -r line; do
                  case "$line" in
                    # noctalia colors the tag: "[\e[34mworkspace_sway\e[0m] ...".
                    *workspace_sway*"] sway IPC "* | *workspace_sway*"] failed to send sway IPC "*)
                      echo "noctalia lost sway IPC, restarting: $line"
                      systemctl --user --no-block restart noctalia.service
                      ;;
                  esac
                done
            '';
          }
        );
        Restart = "always";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
