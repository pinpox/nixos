{
  pkgs,
  lib,
  ...
}:
{
  imports = [ ];

  nixpkgs.hostPlatform = "aarch64-linux";

  # Lock CPU governor to performance mode (avoid frequency scaling latency)
  powerManagement.cpuFreqGovernor = "performance";

  boot.kernel.sysctl = {
    "vm.swappiness" = 0;
  };
}
