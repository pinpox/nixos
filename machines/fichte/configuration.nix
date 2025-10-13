{
  nixos-hardware,
  lib,
  ...
}:
{

  imports = [
    ./disko-config-btrfs.nix
    nixos-hardware.nixosModules.lenovo-thinkpad-t490
  ];

  networking.hostName = "fichte";

  # Set keymap to DE on this device
  console.keyMap = lib.mkForce "de";
  services.xserver = {
    layout = "de";
    xkbOptions = "eurosign:e";
  };
}
