{ config, pkgs, lib, nur, awesome-config, wallpaper-generator, flake-inputs, ...
}:
let
  vars = import ./vars.nix;
  splitString = str:
    builtins.filter builtins.isString (builtins.split "\n" str);
in {

  # Imports
  imports = [
    # ./modules/autorandr.nix
    ./modules/grobi.nix
    # ./modules/i3.nix
    # ./modules/newsboat.nix
    # ./modules/polybar.nix
    ./modules/rofi
    ./modules/alacritty.nix
    ./modules/awesome.nix
    ./modules/chromium.nix
    ./modules/credentials.nix
    ./modules/dunst.nix
    ./modules/fonts.nix
    ./modules/games.nix
    ./modules/git.nix
    ./modules/go.nix
    ./modules/gtk.nix
    ./modules/neomutt.nix
    ./modules/picom.nix
    ./modules/shell
    ./modules/tmux
    ./modules/vim
    ./modules/xdg.nix
    ./modules/xresources.nix
    ./modules/xscreensaver.nix
    ./modules/wezterm
    ./modules/firefox
    ./modules/zk
  ];

  _module.args.utils = import ../utils { inherit pkgs; };

  pinpox.programs = {
    firefox.enable = true;
    tmux.enable = true;
    wezterm.enable = true;
    zk.enable = true;
    rofi.enable = true;
  };

  # Allow "unfree" licenced packages
  nixpkgs.config = { allowUnfree = true; };

  # Install these packages for my user
  home.packages = with pkgs; [

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
    httpie
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
    xclip
    xfce.exo # thunar "open terminal here"
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.tumbler # thunar thumbnails
    xfce.xfce4-volumed-pulse
    xfce.xfconf # thunar save settings
    xorg.xrandr
    yubioath-desktop
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

  # Include man-pages
  manual.manpages.enable = true;

  # Environment variables
  systemd.user.sessionVariables = { ZDOTDIR = "/home/pinpox/.config/zsh"; };

  home.sessionVariables = {
    # LIBGL_ALWAYS_SOFTWARE = "1";
    # Workaround for alacritty (breaks wezterm and other apps!)
    EDITOR = "nvim";
    VISUAL = "nvim";
    ZDOTDIR = "/home/pinpox/.config/zsh";
  };

  programs.neovim.package = pkgs.neovim-nightly;

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

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

    # syncthing = {
    #   enable = true;
    #   tray.enable = true;
    # };

  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";
}
