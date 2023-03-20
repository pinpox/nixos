{ config
, pkgs
, lib
, nur
, wallpaper-generator
  # , dotfiles-awesome
, ...
}:
let

  # pointer = config.home.pointerCursor;
  homeDir = config.home.homeDirectory;
  emoji = "${pkgs.wofi-emoji}/bin/wofi-emoji";


in



{
  # output eDP-1 mode 1920x1080 position 0,0
  #       output DP-1 mode 2560x1440 position 1080,0
  #       output DP-2 mode 2560x1440 position 3640,0

  services.kanshi = {
    enable = true;
    profiles = {

      laptop-only = {
        outputs = [
          {
            criteria = "eDP-1";
            mode = "1920x1080@60Hz";
          }
        ];
      };
      triple-home = {
        outputs = [
          {
            criteria = "eDP-1";
            mode = "1920x1080@60Hz";
            status = "enable";
          }
          {
            criteria = "DP-1";
            mode = "2560x1440@60Hz";
            status = "enable";
          }
          {
            criteria = "DP-2";
            mode = "2560x1440@60Hz";
            status = "enable";
          }
        ];
      };
    };
  };

  # wayland.windowManager.hyprland.enable = true;
  # wayland.windowManager.hyprland.extraConfig = ''
  #       $mod = ALT
  #       # should be configured per-profile
  #       # monitor = DP-1, preferred, auto, auto
  #       # monitor = DP-2, preferred, auto, auto
  #       # monitor = eDP-1, preferred, auto, auto
  #       # workspace = eDP-1, 1
  #       # workspace = DP-1, 10
  #       # workspace = DP-2, 10
  #       # scale apps


  #       # select area to perform OCR on
  #       monitor=,preferred,auto,auto

  #       exec-once ${pkgs.waybar}/bin/waybar


  #       misc {
  #         # disable auto polling for config file changes
  #         # disable_autoreload = true
  #         focus_on_activate = true
  #         # disable dragging animation
  #         animate_mouse_windowdragging = false
  #       }
  #       # touchpad gestures
  #       # gestures {
  #       #   workspace_swipe = true
  #       #   workspace_swipe_forever = true
  #       # }
  #       input {
  #         kb_layout = us
  #         kb_variant = colemak
  #         kb_options = "caps:swapescape"
  #         # focus change on cursor move
  #         follow_mouse = 1
  #         accel_profile = flat
  #         touchpad {
  #           scroll_factor = 0.3
  #         }
  #       }
  #       general {
  #         gaps_in = 5
  #         gaps_out = 5
  #         border_size = 2
  #         layout = master
  #       }
  #       decoration {
  #         rounding = 5
  #         blur = true
  #         blur_size = 3
  #         blur_passes = 3
  #         blur_new_optimizations = true
  #         drop_shadow = true
  #         shadow_ignore_window = true
  #         shadow_offset = 0 5
  #         shadow_range = 50
  #         shadow_render_power = 3
  #         col.shadow = rgba(00000099)
  #       }
  #       animations {
  #         enabled = true
  #         animation = border, 1, 2, default
  #         animation = fade, 1, 4, default
  #         animation = windows, 1, 3, default, popin 80%
  #         animation = workspaces, 1, 2, default, slide
  #       }
  #       dwindle {
  #         # keep floating dimentions while tiling
  #         pseudotile = true
  #         preserve_split = true
  #       }

  #       master {
  #       new_is_master = true
  #       }
  #       # telegram media viewer
  #       windowrulev2 = float, title:^(Media viewer)$
  #       # make Firefox PiP window floating and sticky
  #       windowrulev2 = float, title:^(Picture-in-Picture)$
  #       windowrulev2 = pin, title:^(Picture-in-Picture)$
  #       # throw sharing indicators away
  #       windowrulev2 = workspace special silent, title:^(Firefox — Sharing Indicator)$
  #       windowrulev2 = workspace special silent, title:^(.*is sharing (your screen|a window)\.)$
  #       # start spotify tiled in ws9
  #       windowrulev2 = tile, class:^(Spotify)$
  #       windowrulev2 = workspace 9 silent, class:^(Spotify)$
  #       # start Discord/WebCord in ws2
  #       windowrulev2 = workspace 2, title:^(.*(Disc|WebC)ord.*)$
  #       # idle inhibit while watching videos
  #       windowrulev2 = idleinhibit focus, class:^(mpv|.+exe)$
  #       windowrulev2 = idleinhibit focus, class:^(firefox)$, title:^(.*YouTube.*)$
  #       windowrulev2 = idleinhibit fullscreen, class:^(firefox)$
  #       windowrulev2 = dimaround, class:^(gcr-prompter)$
  #       # fix xwayland apps
  #       windowrulev2 = rounding 0, xwayland:1, floating:1
  #       windowrulev2 = center, class:^(.*jetbrains.*)$, title:^(Confirm Exit|Open Project|win424|win201|splash)$
  #       windowrulev2 = size 640 400, class:^(.*jetbrains.*)$, title:^(splash)$
  #       # mouse movements
  #       bindm = $mod, mouse:272, movewindow
  #       bindm = $mod, mouse:273, resizewindow
  #       bindm = $mod ALT, mouse:272, resizewindow
  #       # compositor commands
  #       bind = $mod SHIFT, L, exec, pkill Hyprland
  #       bind = $mod, Q, killactive,
  #       bind = $mod, F, fullscreen,
  #       bind = $mod, G, togglegroup,
  #       bind = $mod SHIFT, N, changegroupactive, f
  #       bind = $mod SHIFT, P, changegroupactive, b
  #       bind = $mod, R, togglesplit,
  #       bind = $mod, T, togglefloating,
  #       bind = $mod, P, pseudo,
  #       bind = $mod ALT, ,resizeactive,
  #       # toggle "monocle" (no_gaps_when_only)
  #       $kw = dwindle:no_gaps_when_only
  #       bind = $mod, M, exec, hyprctl keyword $kw $(($(hyprctl getoption $kw -j | jaq -r '.int') ^ 1))
  #       # utility
  #       # launcher
  #       bindr = $mod, SUPER_L, exec, ${pkgs.wofi}/bin/wofi --show run
  #       # terminal
  #       bind = $mod, Return, exec, wezterm
  #       # logout menu
  #       bind = $mod, Escape, exec, wlogout -p layer-shell
  #       # lock screen
  #       bind = $mod, L, exec, loginctl lock-session
  #       # emoji picker
  #       bind = $mod, E, exec, ${emoji}
  #       # move focus
  #       bind = $mod, left, movefocus, l
  #       bind = $mod, right, movefocus, r
  #       bind = $mod, up, movefocus, u
  #       bind = $mod, down, movefocus, d
  #       # window resize
  #       bind = $mod, S, submap, resize
  #       submap = resize
  #       binde = , right, resizeactive, 10 0
  #       binde = , left, resizeactive, -10 0
  #       binde = , up, resizeactive, 0 -10
  #       binde = , down, resizeactive, 0 10
  #       bind = , escape, submap, reset
  #       submap = reset
  #       # media controls
  #       bindl = , XF86AudioPlay, exec, playerctl play-pause
  #       bindl = , XF86AudioPrev, exec, playerctl previous
  #       bindl = , XF86AudioNext, exec, playerctl next
  #       # volume
  #       bindle = , XF86AudioRaiseVolume, exec, wpctl set-volume -l "1.0" @DEFAULT_AUDIO_SINK@ 6%+
  #       binde = , XF86AudioRaiseVolume, exec, ${homeDir}/.config/eww/scripts/volume osd
  #       bindle = , XF86AudioLowerVolume, exec, wpctl set-volume -l "1.0" @DEFAULT_AUDIO_SINK@ 6%-
  #       binde = , XF86AudioLowerVolume, exec, ${homeDir}/.config/eww/scripts/volume osd
  #       bindl = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
  #       bind = , XF86AudioMute, exec, ${homeDir}/.config/eww/scripts/volume osd
  #       bindl = , XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
  #       # backlight
  #       bindle = , XF86MonBrightnessUp, exec, light -A 5
  #       binde = , XF86MonBrightnessUp, exec, ${homeDir}/.config/eww/scripts/brightness osd
  #       bindle = , XF86MonBrightnessDown, exec, light -U 5
  #       binde = , XF86MonBrightnessDown, exec, ${homeDir}/.config/eww/scripts/brightness osd
  #       # screenshot
  #       # stop animations while screenshotting; makes black border go away
  #       $screenshotarea = hyprctl keyword animation "fadeOut,0,0,default"; grimblast --notify copysave area; hyprctl keyword animation "fadeOut,1,4,default"
  #       bind = , Print, exec, $screenshotarea
  #       bind = $mod SHIFT, R, exec, $screenshotarea
  #       bind = CTRL, Print, exec, grimblast --notify --cursor copysave output
  #       bind = $mod SHIFT CTRL, R, exec, grimblast --notify --cursor copysave output
  #       bind = ALT, Print, exec, grimblast --notify --cursor copysave screen
  #       bind = $mod SHIFT ALT, R, exec, grimblast --notify --cursor copysave screen
  #       # workspaces
  #       # binds mod + [shift +] {1..10} to [move to] ws {1..10}

  #   # Switch workspaces with mod + [0-9]
  #   bind = $mod, 1, workspace, 1
  #   bind = $mod, 2, workspace, 2
  #   bind = $mod, 3, workspace, 3
  #   bind = $mod, 4, workspace, 4
  #   bind = $mod, 5, workspace, 5
  #   bind = $mod, 6, workspace, 6
  #   bind = $mod, 7, workspace, 7
  #   bind = $mod, 8, workspace, 8
  #   bind = $mod, 9, workspace, 9
  #   bind = $mod, 0, workspace, 10

  #   # Move active window to a workspace with mod + SHIFT + [0-9]
  #   bind = $mod SHIFT, 1, movetoworkspace, 1
  #   bind = $mod SHIFT, 2, movetoworkspace, 2
  #   bind = $mod SHIFT, 3, movetoworkspace, 3
  #   bind = $mod SHIFT, 4, movetoworkspace, 4
  #   bind = $mod SHIFT, 5, movetoworkspace, 5
  #   bind = $mod SHIFT, 6, movetoworkspace, 6
  #   bind = $mod SHIFT, 7, movetoworkspace, 7
  #   bind = $mod SHIFT, 8, movetoworkspace, 8
  #   bind = $mod SHIFT, 9, movetoworkspace, 9
  #   bind = $mod SHIFT, 0, movetoworkspace, 10


  #       # special workspace
  #       bind = $mod SHIFT, grave, movetoworkspace, special
  #       bind = $mod, grave, togglespecialworkspace, eDP-1
  #       # cycle workspaces
  #       bind = $mod, bracketleft, workspace, m-1
  #       bind = $mod, bracketright, workspace, m+1
  #       # cycle monitors
  #       bind = $mod SHIFT, braceleft, focusmonitor, l
  #       bind = $mod SHIFT, braceright, focusmonitor, r
  # '';


  home.file = {
    # ".config/awesome".source = "${dotfiles-awesome}/dotfiles";
    ".local/share/wallpaper-generator".source = wallpaper-generator;
  };

  home.keyboard = {
    variant = "colemak";

    layout = "us";
    options = "caps:swapescape";
  };


  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      # Use kitty as default terminal
      terminal = "${pkgs.lxterminal}/bin/lxterminal";
      startup = [
        # Launch Firefox on start
        # { command = "firefox"; }
      ];
      input = {
        "*" = {
          xkb_layout = "us";
          xkb_variant = "colemak";
        };
      };

      # output = {
      ##Phillips
      #DP-1 = {
      #  mode = "2560x1440@60";
      #};
      ## NZXT
      #DP-2 = {
      #  mode = "2560x1440@60";
      #};
      #};
    };
  };


  pinpox = {
    defaults = {
      xresources.enable = true;
      xdg.enable = true;
      shell.enable = true;
      gtk.enable = true;
      fonts.enable = true;
      credentials.enable = true;
      git.enable = true;
    };

    services.ntfy-notify.enable = true;

    programs = {
      pandoc.enable = true;
      alacritty.enable = true;
      zellij.enable = true;
      chromium.enable = true;
      dunst.enable = true;
      picom.enable = true;
      nvim.enable = true;
      xscreensaver.enable = true;
      firefox.enable = true;
      tmux.enable = true;
      wezterm.enable = true;
      zk.enable = true;
      rofi.enable = false;
      go.enable = true;
      awesome.enable = false;
    };
  };

  # Install these packages for my user
  home.packages = with pkgs; [

    river
    wofi
    # way-displays
    waybar
    wl-clipboard

    # From nixpkgs
    inetutils
    nmap
    retroarch
    arandr
    # arduino
    # arduino-cli
    asciinema
    # calibre
    cbatticon
    darktile
    evince
    exa
    gcc
    gimp
    gtk_engines
    h # https://github.com/zimbatm/h
    htop
    fd
    hugo
    imagemagick
    libnotify
    lxappearance
    manix
    matcha-gtk-theme
    meld
    networkmanager-openvpn
    networkmanagerapplet
    nitrogen
    nix-index
    openvpn
    papirus-icon-theme
    recursive
    pavucontrol
    pkg-config
    playerctl
    pre-commit
    scrot
    signal-desktop
    spotify
    tealdeer
    tfenv
    thunderbird-bin
    timewarrior
    sqlite
    unzip
    viewnior
    vlc
    xarchiver
    gnome.file-roller
    xfce.exo # thunar "open terminal here"
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.tumbler # thunar thumbnails
    xfce.xfce4-volumed-pulse
    xfce.xfconf # thunar save settings
    xorg.xrandr
    # yubioath-desktop
    # xfce.thunar
    (xfce.thunar.override {
      thunarPlugins = with pkgs; [
        xfce.thunar-volman
        xfce.thunar-archive-plugin
        xfce.thunar-media-tags-plugin
      ];
    })
  ];

  xdg = {
    enable = true;
    configFile = {


      river-config = {
        target = "river/init_exta";
        text = ''
            riverctl map normal Super p spawn "${pkgs.wofi}/bin/wofi --show run"
            ${pkgs.waybar}/bin/waybar
            # ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 1920x1080 --pos 0,0 \
          # --output DP-1 --mode 2560x1440 --pos 4480,0 \
          # --output DP-2 --mode 2560x1440@164.54 --pos 1920,0
        '';
        executable = true;
      };



      thunar_actions = {
        target = "Thunar/uca.xml";
        text = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <actions>
            <action>
              <icon>utilities-terminal</icon>
              <name>Open Terminal Here</name>
              <unique-id>1604472351415438-1</unique-id>
              <command>wezterm start --cwd %f</command>
              <description>Example for a custom action</description>
              <patterns>*</patterns>
              <startup-notify/>
              <directories/>
            </action>
          </actions>
        '';
      };
    };
  };

  services = {

    # espanso = {
    #   enable = true;
    #   settings = {
    #     matches = [
    #       {
    #         # Simple text replacement
    #         trigger = ":espanso";
    #         replace = "Hi there!";
    #       }
    #       {
    #         # Dates
    #         trigger = ":date";
    #         replace = "{{mydate}}";
    #         vars = [{
    #           name = "mydate";
    #           type = "date";
    #           params = { format = "%Y-%m-%d"; };
    #         }];
    #       }
    #       {
    #         # Shell commands
    #         trigger = ":shell";
    #         replace = "{{output}}";
    #         vars = [{
    #           name = "output";
    #           type = "shell";
    #           params = { cmd = "echo 'Hello from your shell'"; };
    #         }];
    #       }
    #     ];
    #   };
    # };
    # Applets, shown in tray
    # Networking
    network-manager-applet.enable = true;

    # Bluetooth
    blueman-applet.enable = true;

    # Pulseaudio
    pasystray.enable = true;

    # Battery Warning
    cbatticon.enable = true;

    # Keyring
    gnome-keyring = { enable = true; };

  };
}
