{
  pkgs,
  ...
}:
{

  imports = [ ../common.nix ];

  config = {

    home.keyboard = {
      # variant = "colemak";
      layout = "us";
    };

    pinpox = {

      defaults = {
        xdg.enable = true;
        calendar.enable = false;
        shell.enable = true;
        gtk.enable = true;
        fonts.enable = false; # Disabled - noto-fonts-color-emoji can't cross-compile
        credentials.enable = true;
        git.enable = true;
      };

      services.theme-switcher.enable = true;

      programs.ssh = {
        enable = true;
      };

      programs = {
        zellij.enable = true;
        tmux.enable = true;
        foot.enable = true;
        sway.enable = true;
        swaylock.enable = true;
        waybar.enable = true;
        mako.enable = true;
      };
    };

    # Install these packages for my user
    home.packages = with pkgs; [
      swaynotificationcenter
      tea

      chafa
      duf
      evince
      eza
      fd
      gcc
      adwaita-icon-theme
      gtk_engines
      htop
      iputils
      libnotify
      ncdu
      networkmanagerapplet
      nix-index
      pavucontrol
      playerctl
      sqlite
      tealdeer
      unzip
      xdg-utils
      thunar-archive-plugin
      thunar-volman
      tumbler # thunar thumbnails
      xfconf # thunar save settings
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
