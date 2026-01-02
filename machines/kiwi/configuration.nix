{
  nixos-hardware,
  lib,
  ...
}:
{

  # `boltctl`, to authorize Thunderbolt docs (e.g. lenovo dock)
  services.hardware.bolt.enable = true;

  # Trust all thunderbolt devices
  # boot.kernelParams = [ "thunderbolt.host_reset=0" ];
  # services.udev.extraRules = ''
  #   ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
  # '';

  hardware.fw-fanctrl.enable = true;

  imports = [
    ../../39c3-wifi.nix
    ./disko-config-btrfs.nix
    # ./framework.nix
    nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];
  hardware.rtl-sdr.enable = true;

  # TODO: remove when 6.15.1 hits unstable
  # boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.amdgpu.opencl.enable = true;

  programs.adb.enable = true;
  users.users.pinpox.extraGroups = [ "adbusers" ];

  networking.hostName = "kiwi";

  # Games
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  # TODO https://github.com/NixOS/nixpkgs/issues/467803
  # hardware.xone.enable = true;

  # For dual-boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;

  # Remap Caps Lock to Esc and vice versa
  services.udev.extraHwdb = ''
    evdev:atkbd:dmi:*
      KEYBOARD_KEY_3a=esc      # Caps Lock -> Esc
      KEYBOARD_KEY_01=capslock # Esc -> Caps Lock
  '';
}
