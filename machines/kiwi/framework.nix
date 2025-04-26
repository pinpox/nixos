{ pkgs, lib, ... }:
{
  # For fingerprint support
  services.fprintd.enable = lib.mkDefault true;

  # Ethernet expansion card support
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", ATTR{power/autosuspend}="20"
  '';

  environment.systemPackages = [ pkgs.framework-tool ];

  # Needed for desktop environments to detect/manage display brightness
  hardware.sensor.iio.enable = lib.mkDefault true;
}
