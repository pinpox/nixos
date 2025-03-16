# Configuration file for ahorn
{
  config,
  pkgs,
  nixos-hardware,
  ...
}:
{

  imports = [
    nixos-hardware.nixosModules.lenovo-thinkpad-t480s
    ./hardware-configuration.nix
  ];

  clan.core.networking.targetHost = "ahorn";

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.2";
    hostname = "ahorn";
  };

  services.gnome.gnome-keyring.enable = true;

  hardware.keyboard.qmk.enable = true;
  services.udev.packages = [ pkgs.qmk-udev-rules ];

  boot.initrd.services.udev.rules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2341", ATTRS{idProduct}=="8037", MODE:="0666"
  '';

  # Register a v4l2loopback device at boot
  boot.kernelModules = [ "v4l2loopback" ];

  boot.extraModulePackages = [
    config.boot.kernelPackages.v4l2loopback
    config.boot.kernelPackages.v4l2loopback.out
  ];

  # Enable audio producion for pinpox
  home-manager.users.pinpox.pinpox.defaults.audio-recording.enable = true;

  # To build raspi images
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  boot.blacklistedKernelModules = [ "nouveau" ];

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
