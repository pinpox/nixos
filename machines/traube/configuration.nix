{
  config,
  pkgs,
  ...
}:
let
  p0BaseUrl = "https://inference.p0.contact/v1";
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

  # No GPU on this board, and nothing here needs GPU userspace.
  hardware.graphics.enable = false;

  # Lightweight tools for poking at the box over ssh.
  environment.systemPackages = [
    pkgs.curl
    pkgs.jq
  ];

  # The hermes agent VMs run here, not on the laptops: the box is always on,
  # so a session survives a closed lid. Every desktop with the clan hermes
  # `client` role forwards this host's loopback dashboard port over SSH.
  #
  # The VMs talk to the p0 inference endpoint — no self-hosted llama-swap and
  # no OpenRouter on this host. `key_env` names the variable hermes reads from
  # the guest's .env; `secretEnv` rides the clan var in as a systemd
  # credential under that name.
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
}
