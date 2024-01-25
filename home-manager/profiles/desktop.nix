{ system-config, pkgs, ... }: {


  programs.helix = {
    enable = true;

    # https://docs.helix-editor.com/languages.html
    languages = {
      language = [{
        name = "nix";
        auto-format = false;
        formatter.command = "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt";
      }];
    };

    settings = {

      editor = {
        indent-guides = {
          render = true;
        };
        bufferline = "multiple";
        cursorline = true;
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        lsp.display-messages = true;
      };

      theme = "catppuccin_mocha";

      keys = {
        normal = { ";" = "command_mode"; };
        select = { ";" = "command_mode"; };
      };

    };
    # themes = { };
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

    programs =
      let
        inXserver = system-config.pinpox.services.xserver.enable;
      in
      {
        obs-studio.enable = true;
        pandoc.enable = true;
        k9s.enable = true;
        zellij.enable = true;
        chromium.enable = true;
        nvim.enable = true;
        firefox.enable = true;
        tmux.enable = true;
        wezterm.enable = true;
        zk.enable = true;
        go.enable = true;

        # XServer only
        alacritty.enable = inXserver;
        rofi.enable = inXserver;
        awesome.enable = inXserver;
        xscreensaver.enable = inXserver;
        dunst.enable = inXserver;
        picom.enable = inXserver;

        # Wayland only
        foot.enable = !inXserver;
        sway.enable = !inXserver;
        swaylock.enable = !inXserver;
        river.enable = !inXserver;
        waybar.enable = !inXserver;
        mako.enable = !inXserver;
        kanshi.enable = !inXserver;
      };
  };


  # Install these packages for my user
  home.packages = with pkgs; [
    swaynotificationcenter

    zotero

    # From nixpkgs
    # arduino
    # arduino-cli
    # calibre
    # recursive
    # retroarch
    asciinema
    cbatticon
    evince
    eza
    fd
    gcc
    gimp
    gnome.adwaita-icon-theme
    gnome.file-roller
    gtk_engines
    h # https://github.com/zimbatm/h
    helix
    htop
    imagemagick
    inetutils
    libnotify
    lxappearance
    manix
    matcha-gtk-theme
    meld
    ncdu
    networkmanager-openvpn
    networkmanagerapplet
    nextcloud-client
    nitrogen
    nix-index
    nmap
    openvpn
    papirus-icon-theme
    pavucontrol
    pkg-config
    playerctl
    pre-commit
    scrot
    signal-desktop
    spotify
    sqlite
    taskwarrior
    tealdeer
    tfenv
    thunderbird-bin
    timewarrior
    unzip
    viewnior
    vlc
    xarchiver
    xdg-utils
    xfce.exo # thunar "open terminal here"
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.tumbler # thunar thumbnails
    xfce.xfce4-volumed-pulse
    xfce.xfconf # thunar save settings
    # yubioath-desktop
    # xfce.thunar
    (xfce.thunar.override {
      thunarPlugins = with pkgs; [
        xfce.thunar-volman
        xfce.thunar-archive-plugin
        xfce.thunar-media-tags-plugin
      ];
    })
  ] ++
  # Packages only useful when using xserver
  lib.optionals system-config.pinpox.services.xserver.enable [
    arandr
    xorg.xrandr
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
