{ config, libs, pkgs, lib, ... }:

{

  system.stateVersion = "20.09";

  boot = {
    loader.grub.enable = false;
    loader.raspberryPi.enable = true;
    loader.raspberryPi.version = 4;
    kernelPackages = pkgs.linuxPackages_rpi4;
  };
  boot.consoleLogLevel = lib.mkDefault 7;

  # Increase `cma` to 64M to allow to use all of the RAM.
  # NOTE: this disables the serial console. Add
  # "console=ttyS0,115200n8" "console=ttyAMA0,115200n8" to restore.
  boot.kernelParams = [ "cma=64M" "console=tty0" ];

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # bzip2 compression takes loads of time with emulation, skip it. Enable this if you're low
  # on space.
  sdImage.compressImage = false;

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Berlin";

  networking = {
    hostName = "nixos-raspi";
    useDHCP = false;
    interfaces.eth0.useDHCP = true;
  };

  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
  };

  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];

  users.users.pinpox = {
    isNormalUser = true;
    home = "/home/pinpox";
    extraGroups = [ "wheel" "networkmanager" ];
    # openssh.authorizedKeys.keys = [ "$YOUR_PUBLIC_KEY" ];
  };

  fileSystems = lib.mkForce {
    # There is no U-Boot on the Pi 4, thus the firmware partition needs to be mounted as /boot.
    "/boot" = {
      device = "/dev/disk/by-label/FIRMWARE";
      fsType = "vfat";
    };
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };

}
