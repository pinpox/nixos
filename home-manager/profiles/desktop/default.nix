{
  pkgs,
  ...
}:
{

  imports = [ ../common.nix ];

  config = {

    home.keyboard = {
      variant = "colemak";
      layout = "us";
    };

    pinpox = {

      defaults = {
        xdg.enable = true;
        calendar.enable = false;
        shell.enable = true;
        gtk.enable = true;
        fonts.enable = true;
        credentials.enable = true;
        email.enable = true;
        git.enable = true;
      };

      services.theme-switcher.enable = true;

      programs.ssh = {
        enable = true;
      };

      programs = {
        games.enable = true;
        obs-studio.enable = false;
        pandoc.enable = true;
        k9s.enable = false;
        zed.enable = false;
        helix.enable = false;
        easyeffects.enable = false;
        zellij.enable = true;
        chromium.enable = true;
        firefox.enable = true;
        tmux.enable = true;
        zk.enable = true;
        taskwarrior.enable = true;
        go.enable = true;
        foot.enable = true;
        rio.enable = true;
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
      spotify
      mpv
      sysz
      thunderbird-bin
      deluge
      (audacious.override { withPlugins = true; })
      file-roller
      imagemagick
      swaynotificationcenter
      tea
      claude-code
      chafa
      asciinema
      cbatticon
      duf
      evince
      eza
      fd
      gcc
      # gimp
      adwaita-icon-theme
      gtk_engines
      h # https://github.com/zimbatm/h
      htop
      iputils
      libnotify
      manix
      matcha-gtk-theme
      meld
      ncdu
      networkmanagerapplet
      nextcloud-client
      nix-index
      nmap
      papirus-icon-theme
      pavucontrol
      pkg-config
      playerctl
      pre-commit
      signal-desktop
      sqlite
      tealdeer
      unzip
      viewnior
      vlc
      xarchiver
      xdg-utils
      # xfce-exo # thunar "open terminal here"
      thunar-archive-plugin
      thunar-volman
      tumbler # thunar thumbnails
      xfce4-volumed-pulse
      xfconf # thunar save settings
      # yubioath-desktop
      # thunar
      (thunar.override {
        thunarPlugins = with pkgs; [
          thunar-volman
          thunar-archive-plugin
          thunar-media-tags-plugin
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
