{ config
, pkgs
, lib
, nur
, wallpaper-generator
, colorscheme
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

  programs.foot = {
    enable = true;
    server.enable = true;
    settings = {

      main = {
        term = "xterm-256color";

        font = "Berkeley Mono:size=11";
        # dpi-aware = "yes"; # Defaults to auto
      };

      scrollback = {
        lines = 10000;
      };

      cursor = {
        style = "beam";
        blink = "yes";
        # beam-thickness = 
      };

      colors = {

        # alpha=1.0
        background = "${colorscheme.Black}";
        foreground = "${colorscheme.White}";

        ## Normal/regular colors (color palette 0-7)
        regular0 = "${colorscheme.Black}"; # black
        regular1 = "${colorscheme.Red}"; # red
        regular2 = "${colorscheme.Green}"; # green
        regular3 = "${colorscheme.Yellow}"; # yellow
        regular4 = "${colorscheme.Blue}"; # blue
        regular5 = "${colorscheme.Magenta}"; # magenta
        regular6 = "${colorscheme.Cyan}"; # cyan
        regular7 = "${colorscheme.White}"; # white

        ## Bright colors (color palette 8-15)
        bright0 = "${colorscheme.BrightBlack}"; # black
        bright1 = "${colorscheme.BrightRed}"; # red
        bright2 = "${colorscheme.BrightGreen}"; # green
        bright3 = "${colorscheme.BrightYellow}"; # yellow
        bright4 = "${colorscheme.BrightBlue}"; # blue
        bright5 = "${colorscheme.BrightMagenta}"; # magenta
        bright6 = "${colorscheme.BrightCyan}"; # cyan
        bright7 = "${colorscheme.BrightWhite}"; # white
      };

      # mouse = {
      #   hide-when-typing = "yes";
      # };

    };
  };

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

  home.file = {
    # ".config/awesome".source = "${dotfiles-awesome}/dotfiles";
    ".local/share/wallpaper-generator".source = wallpaper-generator;
  };

  home.keyboard = {
    variant = "colemak";

    layout = "us";
    options = "caps:swapescape";
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
      dunst.enable = false;
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
      sway.enable = true;
      river.enable = true;
      kanshi.enable = true;
      hyprland.enable = false;
    };
  };

  # Install these packages for my user
  home.packages = with pkgs; [

    river-luatile

    wofi
    # way-displays
    waybar
    wl-clipboard
    wlr-randr

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
