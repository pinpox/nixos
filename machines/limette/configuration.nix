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

}
