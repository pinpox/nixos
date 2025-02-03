# Configuration file for ahorn
{
  config,
  retiolum,
  pkgs,
  lib,
  nixos-hardware,
  # inovex-mdm,
  ...
}:
{

  # clan.core.state.userdata.folders = [
  #   "/home/pinpox/test-backup"
  #   "/home/pinpox/test-backup2"
  # ];

  #   nixpkgs.config.packageOverrides = pkgs: {
  #     vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  #   };

  #     environment.systemPackages = with pkgs; [
  #       intel-gpu-tools
  #       vaapiIntel
  #       intel-media-driver
  #       vaapi-intel-hybrid
  #       xorg.xf86videointel
  #     ];

  services.gnome.gnome-keyring.enable = true;

  hardware.keyboard.qmk.enable = true;

  # RTL-SDR
  # hardware.rtl-sdr.enable = true;
  # users.users.pinpox.extraGroups = [ "plugdev" ];

  boot.initrd.services.udev.rules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="8037", MODE:="0666"
  '';

  # Enable driver for Focusrite Scarlett 2i2 Gen3.
  # This can be removed when we reach Linux Kernel 6.7, as it includes the driver by default
  # See: https://github.com/geoffreybennett/alsa-scarlett-gui/blob/master/INSTALL.md#enabling-the-driver
  boot.extraModprobeConfig = ''
    options snd_usb_audio vid=0x1235 pid=0x8210 device_setup=1
  '';

  boot.extraModulePackages = [
    config.boot.kernelPackages.v4l2loopback
    config.boot.kernelPackages.v4l2loopback.out
  ];

  # Register a v4l2loopback device at boot
  boot.kernelModules = [ "v4l2loopback" ];

  # boot.extraModprobeConfig = ''
  #   options v4l2loopback exclusive_caps=1 video_nr=9 card_label=a7III
  # '';

  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-t480s
    ./hardware-configuration.nix
    retiolum.nixosModules.retiolum
    # inovex-mdm.nixosModules.default

    #retiolum.nixosModules.ca
  ];

  lollypops.secrets.files."inovex-mdm/mdm-create-token" = { };

  clan.core.networking.targetHost = "ahorn";

  # services.inovex-mdm = {
  #   enable = true;
  #   userhome = "/home/pinpox";
  #   tokenFile = "${config.lollypops.secrets.files."inovex-mdm/mdm-create-token".path}";
  #   screenLockTimeout = "300";
  # };

  programs.sway.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    NIXOS_OZONE_WL = "1";
  };

  # You can turn on native Wayland support in all chrome and most electron apps
  # by setting an environment variable:

  xdg.portal = {

    enable = true;

    wlr = {
      enable = true;
      settings = {

        # See xdg-desktop-portal-wlr(5) for supported values.
        screencast = {
          # output_name = "HDMI-A-1";
          max_fps = 30;
          # exec_before = "disable_notifications.sh";
          # exec_after = "enable_notifications.sh";
          chooser_type = "simple";
          chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
        };
      };
    };
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
  };

  services.fwupd.enable = true;
  services.acpid.enable = true;

  # Often hangs
  systemd.services = {
    NetworkManager-wait-online.enable = lib.mkForce false;
    systemd-networkd-wait-online.enable = lib.mkForce false;
  };

  services.udev.packages = [

    pkgs.via
    pkgs.qmk-udev-rules # For QMK/Via
    pkgs.libsigrok # For pulseview
  ];

  hardware.sane.enable = true;
  users.users.pinpox.extraGroups = [
    "scanner"
    "lp"
  ];

  # Enable audio producion for pinpox
  home-manager.users.pinpox.pinpox.defaults.audio-recording.enable = true;

  # To build raspi images
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Retiolum config
  networking.retiolum = {
    ipv4 = "10.243.100.100";
    ipv6 = "42:0:3c46:519d:1696:f464:9756:8727";
  };

  lollypops.extraTasks = {

    rebuild-nosecrets = {
      desc = "Rebuild without deloying secrets";
      cmds = [ ];
      deps = [
        "deploy-flake"
        "rebuild"
      ];
    };
  };

  lollypops.secrets.files = {
    "retiolum/rsa_priv" = { };
    "retiolum/ed25519_priv" = { };
  };

  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = "${config.lollypops.secrets.files."retiolum/rsa_priv".path}";
    ed25519PrivateKeyFile = "${config.lollypops.secrets.files."retiolum/ed25519_priv".path}";
  };

  boot.blacklistedKernelModules = [ "nouveau" ];

  environment.systemPackages = [
    pkgs.via

    pkgs.libimobiledevice
    pkgs.ifuse # optional, to mount using 'ifuse'
    pkgs.xdg-desktop-portal
    pkgs.xdg-desktop-portal-wlr
  ];

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.2";
    hostname = "ahorn";
  };

  # Encrypted drive to be mounted by the bootloader. Path of the device will
  # have to be changed for each install.
  boot.initrd.luks.devices = {
    root = {
      # Get UUID from blkid /dev/sda2
      device = "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";
      preLVM = true;
      allowDiscards = true;
    };
  };

}
