{ config, pkgs, lib, ... }:
let
  vars = import ./vars.nix;
  splitString = str:
    builtins.filter builtins.isString (builtins.split "\n" str);
in {

  # Allow "unfree" licenced packages
  nixpkgs.config = { allowUnfree = true; };

  # Install these packages for my user
  home.packages = with pkgs; [
    # material-design-icons
    # material-icons
    # nerdfonts
    # paper-gtk-theme
    arandr
    arc-theme
    arduino
    arduino-cli
    asciinema
    cbatticon
    evince
    exa
    gcc
    gimp
    gtk_engines
    htop
    httpie
    hugo
    imagemagick
    libnotify
    lxappearance
    manix
    matcha-gtk-theme
    networkmanager-openvpn
    networkmanagerapplet
    nitrogen
    nix-index
    openvpn
    papirus-icon-theme
    pavucontrol
    pkg-config
    playerctl
    retroarch
    scrot
    seafile-client
    signal-desktop
    spotify
    styx
    tealdeer
    thunderbird-bin
    unzip
    vagrant
    viewnior
    virt-manager
    # virt-manager
    # universal-ctags # Support for Markdwon tags in vim with tagbar
    viewnior
    vlc
    xarchiver
    xclip
    xfce.gvfs
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.xfce4-volumed-pulse
    xorg.xrandr
  ];

  # Imports
  imports = [
    # ./grobi.nix
    # ./i3.nix
    # ./polybar.nix
    # ./rofi.nix
    # ./autorandr.nix
    ./xresources.nix
    ./alacritty.nix
    ./browsers.nix
    ./credentials.nix
    ./dunst.nix
    ./games.nix
    ./git.nix
    ./go.nix
    ./gtk.nix
    ./awesome.nix
    ./neomutt.nix
    # ./newsboat.nix
    ./picom.nix
    ./shell.nix
    ./vim.nix
    ./xdg.nix
  ];

  # Include man-pages
  manual.manpages.enable = true;

  # Environment variables
  home.sessionVariables = {

    # Workaround for alacritty
    LIBGL_ALWAYS_SOFTWARE = "1";
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

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

    # Screensaver and lock
    xscreensaver = {
      enable = true;
      settings = {
        fadeTicks = 20;
        lock = true;
        mode = "blank";
      };
    };
  };

  # TODO programs.mvp
  # TODO ssh client config

  # TODO check out these services
  # random-background = {}
  # spotifyd = {}
  # syncthing = {}
  # udiskie= {}
  # xsuspender

  # General stuff TODO
  # home.activation...
  # home.file...
  # home.keyboard...
  # home.language...
  # readline
  # accounts.email.accounts.<name>.gpg
  # Fontconfig
  # fonts.fontconfig.enable

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
