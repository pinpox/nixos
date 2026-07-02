{
  config,
  modulesPath,
  ...
}:
{
  # Generic Incus/QEMU VM hardware so new machines boot without a per-machine
  # facter report: x86_64 platform + virtio initrd modules (disk/net/etc).
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  nixpkgs.hostPlatform = "x86_64-linux";

  # Deploy settings for every machine, derived from the machine name so new
  # machines need no inventory edits. These VMs are reached at <name>.lan;
  # the clan CLI falls back to clan.core.networking.* when the inventory
  # deploy.* fields are unset.
  clan.core.networking.targetHost = "root@${config.networking.hostName}.lan";
  clan.core.networking.buildHost = "localhost";

  # Incus VM guest: serial console for `incus console` + agent for `incus exec`.
  # These came from the stock Incus image and must be declared explicitly here.
  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0"
  ];
  virtualisation.incus.agent.enable = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };
}
