{
  pkgs,
  nixos-hardware,
  ...
}:
{

  networking.hostName = "limette";

  pinpox.defaults.lvm-grub.enable = true;
  boot.growPartition = true;

  hardware.enableRedistributableFirmware = true;
  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x230
    ./disko-config-btrfs.nix
  ];

  disko.imageBuilder.extraDependencies = [ pkgs.kmod ];

  hardware.graphics.extraPackages = [
    pkgs.intel-media-driver # LIBVA_DRIVER_NAME=iHD
  ];

  boot.loader.efi.canTouchEfiVariables = false;
}
