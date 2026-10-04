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

  # traube (Radxa Orion O6N, CIX P1/CD8180, BIOS 1.0.0-5) hard-freezes every ~2-3 days:
  # unreachable over the network, no shutdown sequence, requires a physical
  # power-cycle. Ruled out: OOM, thermal, disk I/O, and the known O6 SMMU
  # evtq interrupt storm (its firmware precondition is present but the storm
  # never fires here — IRQ 13 stays at 0, no C_BAD_STREAMID events). The
  # remaining armed power-state hazard is cpuidle deep idle: DVFS is pinned
  # (performance governor) and PCIe ASPM is off, but LPI-1/LPI-2 (deep
  # power-down, heavily used) stay enabled — the classic ARM-SBC silent-freeze
  # cause and immature on CIX PSCI firmware. Disable cpuidle so cores fall
  # back to plain WFI. Result: freezes continued with cpuidle off (11.7 d,
  # 3.2 d, 15 min uptimes), and the buddy detector left no pstore dump —
  # consistent with the whole SoC stalling, not one wedged CPU. Kept on to
  # avoid changing two variables at once.
  #
  # Console on both serial (firmware SPCR default) and HDMI; the last entry
  # becomes /dev/console. Without tty0 a hang during boot or a freeze shows
  # nothing on an attached screen.
  #
  # Do NOT arm the SBSA hardware watchdog (systemd RuntimeWatchdogSec,
  # sbsa_gwdt.action=1). Pings never reach it: armed with 30s, it expired
  # exactly 30.0s later with the system healthy (87.44s → 117.44s, pstore).
  # Twice it hard-reset the board mid switch-to-configuration, which
  # truncated /boot/grub/grub.cfg and the new kernel/initrd to 0 bytes and
  # left traube unbootable.
  boot.kernelParams = [
    "cpuidle.off=1"
    "console=ttyAMA0"
    "console=tty0"
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 0;

    # Make the next freeze self-record. The buddy hard-lockup detector is
    # built in (CONFIG_HARDLOCKUP_DETECTOR_BUDDY) and active, but pseudo-NMI
    # is not compiled in. Turn every lockup detector into a panic: the panic
    # dumps the kernel log to efi_pstore, which survives the power-cycle and
    # systemd-pstore archives to /var/lib/systemd/pstore/ on the next boot
    # (verified by the watchdog panic above, BIOS 1.3.1 / 6.18.54).
    # kernel.panic = 0 keeps the panic a HALT, not an auto-reboot, so the
    # trace stays on an attached screen.
    "kernel.hardlockup_panic" = 1;
    "kernel.softlockup_panic" = 1;
    "kernel.panic_on_rcu_stall" = 1;
    "kernel.panic_on_oops" = 1;
    "kernel.panic" = 0;
  };

  # No GPU on this board, and nothing here needs GPU userspace.
  hardware.graphics.enable = false;

  # Lightweight tools for poking at the box over ssh.
  environment.systemPackages = [
    pkgs.curl
    pkgs.jq
  ];

  clan.core.vars.generators."p0-inference-key".prompts."api-key".persist = true;
}
