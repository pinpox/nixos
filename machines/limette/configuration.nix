{
  pkgs,
  lib,
  nixos-hardware,
  disko,
  ...
}:
{

  services.gnome.gnome-keyring.enable = true;
  hardware.keyboard.qmk.enable = true;

  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x230
    # ./hardware-configuration.nix
    ./disko-config.nix
    disko.nixosModules.disko

  ];

  disko.devices.disk.main.imageSize = "40G";
  disko.imageBuilder.extraDependencies = [ pkgs.kmod ];
  #   disko.devices.disk.root.device = "/dev/sda";

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

  environment.systemPackages = [
    pkgs.xdg-desktop-portal
    pkgs.xdg-desktop-portal-wlr
  ];

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.8";
    hostname = "limette";
  };

  # efiSupport = lib.mkForce false;
  # efiInstallAsRemovable = lib.mkForce false;
  # gfxmodeBios = "1600x900";
  # gfxpayloadBios = "text";

  users.users.pinpox.initialPassword = "changeme";

  boot.loader.efi.canTouchEfiVariables = false;
  # boot.loader.grub.device = "/dev/disk/by-label/BOOT";

  # Encrypted drive to be mounted by the bootloader. Path of the device will
  # have to be changed for each install.
  # Get UUID from blkid /dev/sda2
  boot.initrd.luks.devices = {
    "root" = {
      preLVM = true;
      device = lib.mkForce "/dev/disk/by-label/LUKS";
      allowDiscards = true;
    };
  };

}
