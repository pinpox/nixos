{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.hyprland;
in
{
  options.pinpox.programs.hyprland.enable = mkEnableOption "hyprland window manager";

  config = mkIf cfg.enable {

    hyprland.enable = true;
    wayland.windowManager.hyprland.extraConfig = ''
          $mod = ALT
          # should be configured per-profile
          # monitor = DP-1, preferred, auto, auto
          # monitor = DP-2, preferred, auto, auto
          # monitor = eDP-1, preferred, auto, auto
          # workspace = eDP-1, 1
          # workspace = DP-1, 10
          # workspace = DP-2, 10
          # scale apps


          # select area to perform OCR on
          monitor=,preferred,auto,auto

          exec-once ${pkgs.waybar}/bin/waybar


          misc {
            # disable auto polling for config file changes
            # disable_autoreload = true
            focus_on_activate = true
            # disable dragging animation
            animate_mouse_windowdragging = false
          }
          # touchpad gestures
          # gestures {
          #   workspace_swipe = true
          #   workspace_swipe_forever = true
          # }
          input {
            kb_layout = us
            kb_variant = colemak
            kb_options = "caps:swapescape"
            # focus change on cursor move
            follow_mouse = 1
            accel_profile = flat
            touchpad {
              scroll_factor = 0.3
            }
          }
          general {
            gaps_in = 5
            gaps_out = 5
            border_size = 2
            layout = master
          }
          decoration {
            rounding = 5
            blur = true
            blur_size = 3
            blur_passes = 3
            blur_new_optimizations = true
            drop_shadow = true
            shadow_ignore_window = true
            shadow_offset = 0 5
            shadow_range = 50
            shadow_render_power = 3
            col.shadow = rgba(00000099)
          }
          animations {
            enabled = true
            animation = border, 1, 2, default
            animation = fade, 1, 4, default
            animation = windows, 1, 3, default, popin 80%
            animation = workspaces, 1, 2, default, slide
          }
          dwindle {
            # keep floating dimentions while tiling
            pseudotile = true
            preserve_split = true
          }

          master {
          new_is_master = true
          }
          # telegram media viewer
          windowrulev2 = float, title:^(Media viewer)$
          # make Firefox PiP window floating and sticky
          windowrulev2 = float, title:^(Picture-in-Picture)$
          windowrulev2 = pin, title:^(Picture-in-Picture)$
          # throw sharing indicators away
          windowrulev2 = workspace special silent, title:^(Firefox — Sharing Indicator)$
          windowrulev2 = workspace special silent, title:^(.*is sharing (your screen|a window)\.)$
          # start spotify tiled in ws9
          windowrulev2 = tile, class:^(Spotify)$
          windowrulev2 = workspace 9 silent, class:^(Spotify)$
          # start Discord/WebCord in ws2
          windowrulev2 = workspace 2, title:^(.*(Disc|WebC)ord.*)$
          # idle inhibit while watching videos
          windowrulev2 = idleinhibit focus, class:^(mpv|.+exe)$
          windowrulev2 = idleinhibit focus, class:^(firefox)$, title:^(.*YouTube.*)$
          windowrulev2 = idleinhibit fullscreen, class:^(firefox)$
          windowrulev2 = dimaround, class:^(gcr-prompter)$
          # fix xwayland apps
          windowrulev2 = rounding 0, xwayland:1, floating:1
          windowrulev2 = center, class:^(.*jetbrains.*)$, title:^(Confirm Exit|Open Project|win424|win201|splash)$
          windowrulev2 = size 640 400, class:^(.*jetbrains.*)$, title:^(splash)$
          # mouse movements
          bindm = $mod, mouse:272, movewindow
          bindm = $mod, mouse:273, resizewindow
          bindm = $mod ALT, mouse:272, resizewindow
          # compositor commands
          bind = $mod SHIFT, L, exec, pkill Hyprland
          bind = $mod, Q, killactive,
          bind = $mod, F, fullscreen,
          bind = $mod, G, togglegroup,
          bind = $mod SHIFT, N, changegroupactive, f
          bind = $mod SHIFT, P, changegroupactive, b
          bind = $mod, R, togglesplit,
          bind = $mod, T, togglefloating,
          bind = $mod, P, pseudo,
          bind = $mod ALT, ,resizeactive,
          # toggle "monocle" (no_gaps_when_only)
          $kw = dwindle:no_gaps_when_only
          bind = $mod, M, exec, hyprctl keyword $kw $(($(hyprctl getoption $kw -j | jaq -r '.int') ^ 1))
          # utility
          # launcher
          bindr = $mod, SUPER_L, exec, ${pkgs.wofi}/bin/wofi --show run
          # terminal
          bind = $mod, Return, exec, wezterm
          # logout menu
          bind = $mod, Escape, exec, wlogout -p layer-shell
          # lock screen
          bind = $mod, L, exec, loginctl lock-session
          # emoji picker
          bind = $mod, E, exec, ${emoji}
          # move focus
          bind = $mod, left, movefocus, l
          bind = $mod, right, movefocus, r
          bind = $mod, up, movefocus, u
          bind = $mod, down, movefocus, d
          # window resize
          bind = $mod, S, submap, resize
          submap = resize
          binde = , right, resizeactive, 10 0
          binde = , left, resizeactive, -10 0
          binde = , up, resizeactive, 0 -10
          binde = , down, resizeactive, 0 10
          bind = , escape, submap, reset
          submap = reset
          # media controls
          bindl = , XF86AudioPlay, exec, playerctl play-pause
          bindl = , XF86AudioPrev, exec, playerctl previous
          bindl = , XF86AudioNext, exec, playerctl next
          # volume
          bindle = , XF86AudioRaiseVolume, exec, wpctl set-volume -l "1.0" @DEFAULT_AUDIO_SINK@ 6%+
          binde = , XF86AudioRaiseVolume, exec, ${homeDir}/.config/eww/scripts/volume osd
          bindle = , XF86AudioLowerVolume, exec, wpctl set-volume -l "1.0" @DEFAULT_AUDIO_SINK@ 6%-
          binde = , XF86AudioLowerVolume, exec, ${homeDir}/.config/eww/scripts/volume osd
          bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
          bind = , XF86AudioMute, exec, ${homeDir}/.config/eww/scripts/volume osd
          bindl = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
          # backlight
          bindle = , XF86MonBrightnessUp, exec, light -A 5
          binde = , XF86MonBrightnessUp, exec, ${homeDir}/.config/eww/scripts/brightness osd
          bindle = , XF86MonBrightnessDown, exec, light -U 5
          binde = , XF86MonBrightnessDown, exec, ${homeDir}/.config/eww/scripts/brightness osd
          # screenshot
          # stop animations while screenshotting; makes black border go away
          $screenshotarea = hyprctl keyword animation "fadeOut,0,0,default"; grimblast --notify copysave area; hyprctl keyword animation "fadeOut,1,4,default"
          bind = , Print, exec, $screenshotarea
          bind = $mod SHIFT, R, exec, $screenshotarea
          bind = CTRL, Print, exec, grimblast --notify --cursor copysave output
          bind = $mod SHIFT CTRL, R, exec, grimblast --notify --cursor copysave output
          bind = ALT, Print, exec, grimblast --notify --cursor copysave screen
          bind = $mod SHIFT ALT, R, exec, grimblast --notify --cursor copysave screen
          # workspaces
          # binds mod + [shift +] {1..10} to [move to] ws {1..10}

      # Switch workspaces with mod + [0-9]
      bind = $mod, 1, workspace, 1
      bind = $mod, 2, workspace, 2
      bind = $mod, 3, workspace, 3
      bind = $mod, 4, workspace, 4
      bind = $mod, 5, workspace, 5
      bind = $mod, 6, workspace, 6
      bind = $mod, 7, workspace, 7
      bind = $mod, 8, workspace, 8
      bind = $mod, 9, workspace, 9
      bind = $mod, 0, workspace, 10

      # Move active window to a workspace with mod + SHIFT + [0-9]
      bind = $mod SHIFT, 1, movetoworkspace, 1
      bind = $mod SHIFT, 2, movetoworkspace, 2
      bind = $mod SHIFT, 3, movetoworkspace, 3
      bind = $mod SHIFT, 4, movetoworkspace, 4
      bind = $mod SHIFT, 5, movetoworkspace, 5
      bind = $mod SHIFT, 6, movetoworkspace, 6
      bind = $mod SHIFT, 7, movetoworkspace, 7
      bind = $mod SHIFT, 8, movetoworkspace, 8
      bind = $mod SHIFT, 9, movetoworkspace, 9
      bind = $mod SHIFT, 0, movetoworkspace, 10


          # special workspace
          bind = $mod SHIFT, grave, movetoworkspace, special
          bind = $mod, grave, togglespecialworkspace, eDP-1
          # cycle workspaces
          bind = $mod, bracketleft, workspace, m-1
          bind = $mod, bracketright, workspace, m+1
          # cycle monitors
          bind = $mod SHIFT, braceleft, focusmonitor, l
          bind = $mod SHIFT, braceright, focusmonitor, r
    '';





  };
}
