{
  config,
  pkgs,
  ...
}:
{
  # For fingerprint support
  # To enroll prints: `sudo fprint-enroll <username>`
  services.fprintd.enable = true;

  boot.extraModulePackages = with config.boot.kernelPackages; [ framework-laptop-kmod ];

  # Module is not used for Framework EC but causes boot time error log.
  # boot.blacklistedKernelModules = [ "cros-usbpd-charger" ];

  # https://github.com/DHowett/framework-laptop-kmod?tab=readme-ov-file#usage
  # boot.kernelModules = [
  #   "cros_ec"
  #   "cros_ec_lpcs"
  # ];

  # boot.kernelParams = [
  # For Power consumption
  # https://community.frame.work/t/linux-battery-life-tuning/6665/156
  # "nvme.noacpi=1"
  # ];

  # Custom udev rules
  # services.udev.extraRules = ''
  #   # Fix headphone noise when on powersave
  #   # https://community.frame.work/t/headphone-jack-intermittent-noise/5246/55
  #   SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0xa0e0", ATTR{power/control}="on"
  # '';

  # Ethernet expansion card support
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="20"
  '';

  environment.systemPackages = [
    # This adds a patched ectool, to interact with the Embedded Controller
    # Can be used to interact with leds from userspace, etc.
    # Not part of a nixos release yet, so package only gets added if it exists.
    pkgs.fw-ectool
    pkgs.framework-tool
  ];

  # AMD has better battery life with PPD over TLP:
  # https://community.frame.work/t/responded-amd-7040-sleep-states/38101/13
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;

  # Needed for desktop environments to detect/manage display brightness
  hardware.sensor.iio.enable = true;

  # TODO not sure if needed
  # Deactivates light sensor?
  # https://github.com/NixOS/nixpkgs/issues/171093
  # https://wiki.archlinux.org/title/Framework_Laptop#Changing_the_brightness_of_the_monitor_does_not_work
  hardware.acpilight.enable = true;
}
