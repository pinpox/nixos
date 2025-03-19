{
  pkgs,
  lib,
  nixos-hardware,
  ...
}:
{


  clan.core.networking.targetHost = "limette";

  hardware.enableRedistributableFirmware = true;
  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x230
    ./disko-config.nix
  ];

  disko.devices.disk.main.imageSize = "40G";
  disko.imageBuilder.extraDependencies = [ pkgs.kmod ];

  programs.sway.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # LIBVA_DRIVER_NAME=iHD
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
