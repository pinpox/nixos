{
  nixos-hardware,
  config,
  lib,
  pkgs,
  mics-skills,
  ...
}:
let
  p0BaseUrl = "https://inference.p0.contact/v1";
in
{
  hardware.xpadneo.enable = true;

  imports = [
    ./ollama-local.nix
    ./disko-config-btrfs.nix
    # ./framework.nix
    nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  # Skill CLIs on the system PATH so agents on this host can shell out to them
  # as plain binaries (nothing here registers structured skills).
  environment.systemPackages = [
    pkgs.pi
    pkgs.curl
    pkgs.jq
    pkgs.incus.client
    mics-skills.packages.${pkgs.stdenv.hostPlatform.system}.db-cli
  ];

  # The hermes agent VMs talk to the p0 inference endpoint — no self-hosted
  # llama-swap and no OpenRouter on this host. `key_env` names the variable
  # hermes reads from the guest's .env; `secretEnv` rides the clan var in as a
  # systemd credential under that name.
  clan.core.vars.generators."p0-inference-key".prompts."api-key".persist = true;
  services.hermes-microvm = {
    settings.providers.p0 = {
      base_url = p0BaseUrl;
      key_env = "P0_API_KEY";
    };
    # Seed-once: written to the guest config only if the user has not picked a
    # model yet, so runtime /model switches survive reboots.
    initialModel = {
      provider = "p0";
      base_url = p0BaseUrl;
      default = "Qwen3.6-27B-FP8";
    };
    users.pinpox.secretEnv.P0_API_KEY =
      config.clan.core.vars.generators."p0-inference-key".files."api-key".path;
  };

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
