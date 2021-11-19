# Configuration for kartoffel
{ self, ... }: 
{ pkgs, ... }: {

  imports = [ ./hardware-configuration.nix ];

  # environment.systemPackages = [self.wezterm];

services.udev.packages = [pkgs.qmk-udev-rules];

  pinpox.desktop = {
    enable = true;
    wireguardIp = "192.168.7.3";
    hostname = "kartoffel";
    bootDevice = "/dev/disk/by-uuid/608e0e77-eea4-4dc4-b88d-76cc63e4488b";
  };

  age.secrets.secret1.file = "${self.inputs.secrets}/agenix-cli/hosts/kartoffel/some-secret";

  # Video driver for nvidia graphics card
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.blacklistedKernelModules = [ "nouveau" ];


  hardware.sane.enable = true;
    users.users.pinpox.extraGroups = [ "scanner" "lp" ];

  # To build raspi images
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

}
