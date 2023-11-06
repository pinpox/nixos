# Configuration file for ahorn
{ config, retiolum, pkgs, lib, nixos-hardware, ... }: {


  boot.extraModulePackages = [
    config.boot.kernelPackages.v4l2loopback
    config.boot.kernelPackages.v4l2loopback.out
  ];

  # Register a v4l2loopback device at boot
  boot.kernelModules = [
    "v4l2loopback"
  ];


  nixpkgs.overlays = [
    (self: super: {


      rsync = super.rsync.overrideAttrs (_: _: {
        hardeningDisable = [ "fortify" ];
      });


    })
  ];

  # boot.extraModprobeConfig = ''
  #   options v4l2loopback exclusive_caps=1 video_nr=9 card_label=a7III
  # '';

  imports = [

    nixos-hardware.nixosModules.lenovo-thinkpad-t480s
    ./hardware-configuration.nix
    retiolum.nixosModules.retiolum
    #retiolum.nixosModules.ca
  ];

  programs.sway.enable = true;
  hardware.opengl.enable = true;

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

  # Support QMK/Via
  services.udev.packages = [ pkgs.qmk-udev-rules ];

  hardware.sane.enable = true;
  users.users.pinpox.extraGroups = [ "scanner" "lp" ];

  # Enable audio producion for pinpox
  home-manager.users.pinpox.pinpox.defaults.audio-recording.enable = true;

  # To build raspi images
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Retiolum config
  networking.retiolum = {
    ipv4 = "10.243.100.100";
    ipv6 = "42:0:3c46:519d:1696:f464:9756:8727";
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

  # Install reaper
  environment.systemPackages = [
    pkgs.xdg-desktop-portal
    pkgs.xdg-desktop-portal-wlr
  ];


  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.2";
    hostname = "ahorn";
    bootDevice = "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";
  };
}
