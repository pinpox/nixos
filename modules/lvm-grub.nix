{ config, pkgs, lib, ... }: {
  # Use the grub2 boot loader.
  boot = {

    loader = {
      grub.enable = true;
      grub.version = 2;
      grub.device = "nodev";
      grub.efiSupport = true;
      efi.canTouchEfiVariables = true;
    };

    cleanTmpDir = true;
  };
}
