{
  pkgs,
  nixos-hardware,
  lib,
  ...
}:
{

  imports = [
    ../../39c3-wifi.nix
    ./disko-config-btrfs.nix
    nixos-hardware.nixosModules.lenovo-thinkpad-t490
  ];

  environment.systemPackages = with pkgs; [
    python3

  ];

programs.vscode.enable = true;

  networking.hostName = "fichte";

  # Set keymap to DE on this device
  console.keyMap = lib.mkForce "de";
  services.xserver = {
    layout = "de";
    xkbOptions = "eurosign:e";
  };
}
