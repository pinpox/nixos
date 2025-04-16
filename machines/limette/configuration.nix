{
  pkgs,
  lib,
  nixos-hardware,
  config,
  ...
}:
{

  clan.core.networking.targetHost = "limette";

  boot.growPartition = true;

  hardware.enableRedistributableFirmware = true;
  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-x230
    ./disko-config-zfs.nix
  ];

  # disko.devices.disk.main.imageSize = "40G";
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
    hostname = "limette";
  };

  # efiSupport = lib.mkForce false;
  # efiInstallAsRemovable = lib.mkForce false;
  # gfxmodeBios = "1600x900";
  # gfxpayloadBios = "text";

  users.users.pinpox.initialPassword = "changeme";
  boot.loader.efi.canTouchEfiVariables = false;

  # You may also find this setting useful to automatically set the latest compatible kernel:
  boot.kernelPackages = lib.mkDefault config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.supportedFilesystems.zfs = true;

  services.zfs.autoSnapshot = {
    enable = true;
    frequent = 4; # 15 min
    hourly = 24;
    daily = 7;
    weekly = 4;
    monthly = 0;
  };
}
