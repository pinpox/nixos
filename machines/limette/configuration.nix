{
  pkgs,
  nixos-hardware,
  ...
}:
{

  networking.hostName = "limette";

  boot.growPartition = true;

  hardware.enableRedistributableFirmware = true;
  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x230
    ./disko-config-zfs.nix
  ];

  disko.imageBuilder.extraDependencies = [ pkgs.kmod ];


  hardware.graphics.extraPackages = [
    pkgs.intel-media-driver # LIBVA_DRIVER_NAME=iHD
  ];

  pinpox.desktop.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
}
