{
  lib,
  ...
}:
{


  boot.growPartition = true;
  hardware.enableRedistributableFirmware = true;

  imports = [
    ./disko-config-btrfs.nix
    ./framework.nix
  ];

  # disko.devices.disk.main.imageSize = "40G";
  # disko.imageBuilder.extraDependencies = [ pkgs.kmod ];

  programs.sway.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  networking.hostName = "kiwi";
  pinpox.desktop.enable = true;


  # For dual-boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;
}
