# Configuration file for ahorn
{ config, retiolum, pkgs, lib, nixos-hardware, ... }: {

  imports = [

    nixos-hardware.nixosModules.lenovo-thinkpad-t480s
    ./hardware-configuration.nix
    retiolum.nixosModules.retiolum
    #retiolum.nixosModules.ca
  ];


  # services.xserver.enable = true;
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # services.xserver.desktopManager.enlightenment.enable = true;


  # programs.xwayland.enable = true;
  programs.sway.enable = true;
  hardware.opengl.enable = true;


  # environment.sessionVariables = {
  #     MOZ_ENABLE_WAYLAND = "1";
  #   };

  xdg.portal = {

    enable = true;

    wlr = {
      enable = true;
      # settings = {


      #   # See xdg-desktop-portal-wlr(5) for supported values.
      #   screencast = {
      #     # output_name = "HDMI-A-1";
      #     max_fps = 30;
      #     # exec_before = "disable_notifications.sh";
      #     # exec_after = "enable_notifications.sh";
      #     chooser_type = "simple";
      #     chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
      #   };

      # };
    };
    # gtkUsePortal = true;
    extraPortals = [
      # pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-wlr
    ];
  };

  services.fwupd.enable = true;



  # nixpkgs.overlays = [
  #   (self: super: {
  #     enlightenment = super.enlightenment.overrideScope' (gself: gsuper: {
  #       enlightenment = gsuper.enlightenment.override {
  #         waylandSupport = true;
  #       };
  #     });
  #   })
  # ];

  services.acpid.enable = true;

  # Often hangs
  systemd.services = {
    NetworkManager-wait-online.enable = lib.mkForce false;
    systemd-networkd-wait-online.enable = lib.mkForce false;
  };

  # https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1537225778
  # systemd.services.NetworkManager-wait-online = {
  #   serviceConfig.ExecStart = [ "" "${pkgs.networkmanager}/bin/nm-online -q" ];
  # };

  lollypops = {

    secrets = {

      files = {

        secret1 = {
          cmd = "pass test-password";
          # path = "/tmp/testfile5";
        };


        copy-of-secret-1 = {
          cmd = "pass test-password";
          path = "/home/pinpox/test-secret1";
          owner = "pinpox";
          group-name = "users";
        };

        # "nixos-secrets/ahorn/ssh/borg/public" = {
        #   owner = "pinpox";
        #   group-name = "users";
        # };
      };
    };
  };


  # Support QMK/Via
  services.udev.packages = [ pkgs.qmk-udev-rules ];

  hardware.sane.enable = true;
  users.users.pinpox.extraGroups = [ "scanner" "lp" ];

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

  pinpox.services.restic-client.enable = true;

  # Install reaper
  environment.systemPackages = [


    # pkgs.reaper 


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
