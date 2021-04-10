{ config, pkgs, lib, nur, awesome-config, wallpaper-generator, ... }:
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
    retroarch
    # seafile-client
    # universal-ctags # Support for Markdwon tags in vim with tagbar
    # vagrant
    # virt-manager
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
    h # https://github.com/zimbatm/h
    htop
    httpie
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
    thunderbird-bin
    timewarrior
    unzip
    viewnior
    vlc
    xarchiver
    xclip
    xfce.exo # thunar "open terminal here"
    xfce.gvfs
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-volman
    xfce.tumbler # thunar thumbnails
    xfce.xfce4-volumed-pulse
    xfce.xfconf # thunar save settings
    xorg.xrandr
    yubioath-desktop
  ];

  # Imports
  imports = [
    # ./modules/autorandr.nix
    # ./modules/grobi.nix
    # ./modules/i3.nix
    # ./modules/newsboat.nix
    # ./modules/polybar.nix
    # ./modules/rofi.nix
    ./modules/alacritty.nix
    ./modules/awesome.nix
    ./modules/browsers.nix
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
    ./modules/shell.nix
    ./modules/vim
    ./modules/xdg.nix
    ./modules/xresources.nix
    ./modules/xscreensaver.nix
  ];

  # Include man-pages
  manual.manpages.enable = true;

  # Environment variables
  systemd.user.sessionVariables = { ZDOTDIR = "/home/pinpox/.config/zsh"; };

  home.sessionVariables = {
    # Workaround for alacritty
    LIBGL_ALWAYS_SOFTWARE = "1";
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
