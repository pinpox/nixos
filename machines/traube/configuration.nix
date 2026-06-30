{
  pkgs,
  lib,
  ...
}:
let
  # CPU build: traube has no GPU, so drop the spaces-os llama-swap module's
  # default Vulkan llama.cpp for a plain CPU/BLAS one — inference runs on
  # the aarch64 cores (NEON/SVE).
  cpuLlamaCpp = pkgs.llama-cpp.override {
    vulkanSupport = false;
    cudaSupport = false;
    rocmSupport = false;
    metalSupport = false;
    blasSupport = true;
  };

  # Re-fetch just the tiny qwen GGUF. Same url+sha256 as the llama-swap
  # module's bundled copy ⇒ same content-addressed store path, no extra
  # download. (The module also bundles the larger gemma GGUFs; mkForce-ing
  # settings below keeps them out of traube's closure entirely — only this
  # one is ever fetched.)
  qwen05bGguf = builtins.fetchurl {
    url = "https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct-GGUF/resolve/main/qwen2.5-0.5b-instruct-q4_k_m.gguf";
    sha256 = "sha256-dKTajJ/bzRW9H20B1iFBDTHG/ACYb162h4JOe5PXqds=";
  };
  llamaServer = lib.getExe' cpuLlamaCpp "llama-server";
in
{
  nixpkgs.hostPlatform = "aarch64-linux";

  # Lock CPU governor to performance mode (avoid frequency scaling latency)
  powerManagement.cpuFreqGovernor = "performance";

  # traube (Radxa Orion O6, CIX Sky1/CD8180) hard-freezes every ~2-3 days:
  # unreachable over the network, no shutdown sequence, requires a physical
  # power-cycle. Ruled out: OOM, thermal, disk I/O, and the known O6 SMMU
  # evtq interrupt storm (its firmware precondition is present but the storm
  # never fires here — IRQ 13 stays at 0, no C_BAD_STREAMID events). The
  # remaining armed power-state hazard is cpuidle deep idle: DVFS is pinned
  # (performance governor) and PCIe ASPM is off, but LPI-1/LPI-2 (deep
  # power-down, heavily used) stay enabled — the classic ARM-SBC silent-freeze
  # cause and immature on CIX PSCI firmware. Disable cpuidle so cores fall
  # back to plain WFI; this is both the mitigation and the live test for the
  # deep-idle hypothesis.
  boot.kernelParams = [ "cpuidle.off=1" ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 0;

    # Make the next freeze self-record. The buddy hard-lockup detector is
    # built in (CONFIG_HARDLOCKUP_DETECTOR_BUDDY) and active, but pseudo-NMI
    # is not compiled in and nothing currently panics, so a wedged CPU leaves
    # no trace. Panic on hard lockup so the backtrace is dumped to efi_pstore
    # (survives the power-cycle, readable from /sys/fs/pstore afterwards).
    # kernel.panic = 0 keeps the panic a HALT, not an auto-reboot.
    "kernel.hardlockup_panic" = 1;
    "kernel.panic" = 0;
  };

  # LLM endpoint the inventory's `pi` executor (services.pi-sessiond) talks
  # to. CPU-only llama.cpp, single tiny model — this box is the throwaway
  # *second* executor that exercises the multi-executor path, not a
  # performant inference box. hardware.graphics is GPU userspace it lacks.
  hardware.graphics.enable = false;
  services.llama-swap = {
    llama-server-package = cpuLlamaCpp;
    settings = lib.mkForce {
      healthCheckTimeout = 3600;
      logToStdout = "both";
      models."qwen2.5:0.5b".cmd = "${llamaServer} -m ${qwen05bGguf} --port \${PORT}";
    };
  };

  # Lightweight tools the executor's sandboxed agent may shell out to.
  environment.systemPackages = [
    pkgs.curl
    pkgs.jq
  ];
}
