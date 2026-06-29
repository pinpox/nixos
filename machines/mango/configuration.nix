{
  nixos-hardware,
  lib,
  pkgs,
  config,
  mics-skills,
  ...
}:
let
  llamaServer = lib.getExe' config.services.llama-swap.llama-server-package "llama-server";

  # Strix Halo (gfx1151) flags shared by the lazy models below.
  strixArgs = "-ngl 999 -fa on --no-mmap -c 65536 -np 1";
in
{

  imports = [
    ./disko-config-btrfs.nix
    ./lmstudio-models.nix
    # nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  # `boltctl`, to authorize Thunderbolt docs (e.g. lenovo dock)
  # services.hardware.bolt.enable = true;

  # Trust all thunderbolt devices
  # boot.kernelParams = [ "thunderbolt.host_reset=0" ];
  # services.udev.extraRules = ''
  #   ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
  # '';

  hardware = {
    # fw-fanctrl.enable = true;
    # amdgpu.opencl.enable = true;
    xone.enable = true;
  };

  networking.hostName = "mango";

  # Strix Halo unified-memory tuning: IOMMU off + 124 GiB GTT/TTM ceiling.
  boot.kernelParams = [
    "amd_iommu=off"

    "amdgpu.gttsize=126976"

    "ttm.pages_limit=32505856"
  ];

  # Lazy HF models (downloaded on first use), added to the bundled small ones.
  services.llama-swap.settings.models = {
    # default model (inventory.nix)
    "gemma4:12b-q8_0".cmd =
      "${llamaServer} -hf unsloth/gemma-4-12b-it-GGUF --hf-file gemma-4-12b-it-Q8_0.gguf --port \${PORT} ${strixArgs}";

    "gemma4:26b-a4b".cmd =
      "${llamaServer} -hf unsloth/gemma-4-26B-A4B-it-GGUF --hf-file gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf --port \${PORT} ${strixArgs}";

    "ornith-1.0:35b-q4_k_m".cmd =
      "${llamaServer} -hf deepreinforce-ai/Ornith-1.0-35B-GGUF --hf-file ornith-1.0-35b-Q4_K_M.gguf --port \${PORT} ${strixArgs}";

    "supergemma4:26b-uncensored".cmd =
      "${llamaServer} -hf Jiunsong/supergemma4-26b-uncensored-gguf-v2 --hf-file supergemma4-26b-uncensored-fast-v2-Q4_K_M.gguf --port \${PORT} ${strixArgs}";
  };

  # Games
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  programs.gamemode = {
    enable = true;
    settings.custom = {
      # Keep the screen awake while gaming.
      start = "${pkgs.systemd}/bin/systemd-run --user --unit=gaming-wlinhibit --collect ${pkgs.wlinhibit}/bin/wlinhibit";
      end = "${pkgs.systemd}/bin/systemctl --user stop gaming-wlinhibit";
    };
  };
  home-manager.users.pinpox.pinpox.programs.games.enable = true;

  # For dual-boot
  # boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.grub.efiInstallAsRemovable = lib.mkForce false;

  # Enable aarch64 emulation for cross-building ARM images
  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  # Remap Caps Lock to Esc and vice versa
  # services.udev.extraHwdb = ''
  #   evdev:atkbd:dmi:*
  #     KEYBOARD_KEY_3a=esc      # Caps Lock -> Esc
  #     KEYBOARD_KEY_01=capslock # Esc -> Caps Lock
  # '';
}
