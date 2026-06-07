{
  nixos-hardware,
  lib,
  pkgs,
  mics-skills,
  ...
}:
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

  # Strix Halo (Ryzen AI MAX+ 395) kernel tuning. The Radeon 8060S has no
  # VRAM of its own; every GPU memory access is a DMA into system RAM. These
  # three knobs are the community consensus for unified-memory tuning on
  # gfx1151 — measured 5-12% throughput improvement on llama.cpp workloads
  # (Lars Urban benchmarks, kyuz0/amd-strix-halo-toolboxes#66) plus capacity
  # headroom to load models >50 GB.
  boot.kernelParams = [
    # Disable the AMD IOMMU. On a unified-memory APU every GPU weight read
    # is a DMA through the IOMMU page tables; bypassing translation saves
    # 5-12% throughput. Cost: physical PCIe/Thunderbolt devices can DMA
    # into arbitrary system RAM. Acceptable here (home desktop, controlled
    # physical access; remote attacks are unaffected — IOMMU mediates only
    # device-side DMA, not network traffic).
    "amd_iommu=off"

    # Raise the amdgpu GTT pool (the chunk of system RAM exposed to the GPU
    # as "VRAM") from the kernel default of ~62 GiB to 124 GiB. 126976 is
    # MiB → 124 GiB, leaving 4 GiB for the OS. Required to load any model
    # whose weights + KV cache exceed ~50 GiB (70B dense, 120B MoE, etc.).
    "amdgpu.gttsize=126976"

    # Raise the TTM (kernel GPU memory manager) page pin limit to match the
    # GTT ceiling above. Counted in 4 KiB pages: 32505856 × 4 KiB = 124 GiB.
    # Without this, the GTT advertises 124 GiB but allocations start
    # failing mid-load past ~half that — the two must move together.
    "ttm.pages_limit=32505856"
  ];

  # Strix Halo (Radeon 8060S / gfx1151) tuning for the default served model.
  # The spaces-os module bakes a Vulkan + BLAS llama-cpp (rocm explicitly off);
  # RADV is the right backend for gfx1151 on dense models at this size, but
  # the bare `llama-server -m … --port …` template leaves a few APU-specific
  # knobs on the table:
  #
  #   -ngl 999     pin every layer to the GPU instead of relying on the
  #                runtime's --fit auto-sizer; auto-fit is conservative when
  #                multi-slot KV is reserved (see -np below).
  #   -fa on       enable Flash Attention; on Vulkan/RDNA3.5 this is the
  #                Wave32 FA path landed in llama.cpp b8460 — pure upside on
  #                Strix Halo, and required to avoid a few long-input
  #                Vulkan crashes the community has hit.
  #   --no-mmap    bypass mmap'ing the GGUF. On a unified-memory APU mmap
  #                defeats the GTT mapping and paging-through-CPU-pages tanks
  #                throughput; explicit allocation lands the weights straight
  #                into the GPU-accessible GTT pool.
  #   -c 65536     65k single-stream context. spaces-os' default is 256k × 4
  #                slots, which reserves a KV cache budget large enough to
  #                make the auto-fitter hold back layers; 65k is more than
  #                enough headroom for the chat/PWA workload here.
  #   -np 1        one parallel slot. The PWA never fans out concurrent
  #                streams to a single executor, and shrinking slots multiplies
  #                the effective per-stream KV window we actually get.
  services.llama-swap.modelExtraArgs."gemma4:12b-q8_0" = "-ngl 999 -fa on --no-mmap -c 65536 -np 1";

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
      # Hold a Wayland idle-inhibit lock while a game is running so swayidle
      # doesn't lock the screen during controller-only sessions. Run under a
      # transient user unit so the end-hook can stop it cleanly without PID
      # bookkeeping.
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
