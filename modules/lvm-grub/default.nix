{ config, lib, ... }:
with lib;
let cfg = config.pinpox.defaults.lvm-grub;
in
{

  options.pinpox.defaults.lvm-grub = {
    enable = mkEnableOption "LVM/Grub defaults";
  };
  config = mkIf cfg.enable {

    # Use the grub2 boot loader.
    boot = {

      loader = {
        grub.enable = true;

        # Required for LVM
        grub.device = "nodev";

        # Use UEFI support
        grub.efiSupport = true;
        efi.canTouchEfiVariables = true;
      };

      # /tmp is cleaned after each reboot
      tmp.cleanOnBoot = true;
    };
  };
}
