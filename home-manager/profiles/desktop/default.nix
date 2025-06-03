{ system-config, pkgs, ... }:
{

  imports = [ ../common.nix ];

  config = {





    home.keyboard = {
      variant = "colemak";
      layout = "us";
      options = "caps:swapescape";
    };

    pinpox = {
      defaults = {
        xdg.enable = true;
        shell.enable = true;
        gtk.enable = true;
        fonts.enable = true;
        credentials.enable = true;
        git.enable = true;
      };

      programs.ssh = {
        enable = true;
      };

      programs = {
        obs-studio.enable = true;
        pandoc.enable = true;
        k9s.enable = true;
        zed.enable = true;
        helix.enable = true;
        easyeffects.enable = false;
        zellij.enable = true;
        chromium.enable = true;
        firefox.enable = true;
        tmux.enable = true;
        zk.enable = true;
        taskwarrior.enable = true;
        go.enable = true;
        foot.enable = true;
        sway.enable = true;
        swaylock.enable = true;
        river.enable = true;
        waybar.enable = true;
        mako.enable = true;
        kanshi.enable = true;
      };
    };

    # Install these packages for my user
    home.packages = with pkgs; [
      swaynotificationcenter
      tea

      (audacious.override { withPlugins = true; })
      strawberry

      mpv
      # (mpv.override {
      #   scripts = with pkgs.mpvScripts; [
      #     sponsorblock
      #     quality-menu
      #     visualizer
      #     twitch-chat
      #     mpris
      #   ];
      # })

      zotero
      sysz

      deluge
      chafa
      asciinema
      cbatticon
      duf
      evince
      eza
      fd
      gcc
      gimp
      adwaita-icon-theme
      file-roller
      gtk_engines
      h # https://github.com/zimbatm/h
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
      signal-desktop-bin
      spotify
      sqlite
      tealdeer
      thunderbird-bin
      timewarrior
      typst
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
                <command>foot -D %f</command>
                <description>Open terminal in current directory</description>
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
    };
  };
}
