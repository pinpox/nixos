{
  nixos-hardware,
  lib,
  pkgs,
  mics-skills,
  ...
}:
{

  imports = [
    ./ollama-local.nix
    ./disko-config-btrfs.nix
    # ./framework.nix
    nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  # Skill CLIs on the system PATH so the executor's sandboxed agent can
  # shell out to them (the executor doesn't register skill-config, so
  # they're reachable as plain binaries, not structured skills).
  environment.systemPackages = [
    pkgs.pi
    pkgs.curl
    pkgs.jq
    pkgs.incus.client
    mics-skills.packages.${pkgs.stdenv.hostPlatform.system}.db-cli
  ];

  # `boltctl`, to authorize Thunderbolt docs (e.g. lenovo dock)
  services.hardware.bolt.enable = true;

  # Trust all thunderbolt devices
  # boot.kernelParams = [ "thunderbolt.host_reset=0" ];
  # services.udev.extraRules = ''
  #   ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
  # '';

  hardware = {
    fw-fanctrl.enable = true;
    rtl-sdr.enable = true;
    amdgpu.opencl.enable = true;
    xone.enable = true;
  };

  networking.hostName = "kiwi";

  # Games
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  home-manager.users.pinpox.pinpox.programs.games.enable = true;

  # For dual-boot
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;

  # Enable aarch64 emulation for cross-building ARM images
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Remap Caps Lock to Esc and vice versa
  services.udev.extraHwdb = ''
    evdev:atkbd:dmi:*
      KEYBOARD_KEY_3a=esc      # Caps Lock -> Esc
      KEYBOARD_KEY_01=capslock # Esc -> Caps Lock
  '';
}