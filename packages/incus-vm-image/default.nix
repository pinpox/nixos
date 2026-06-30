{
  lib,
  runCommand,
  nixos,
  path,
  pinpox-keys,
  nixos-facter,
}:

# Build a NixOS Incus VM image as a single package bundling the two artifacts
# Incus needs (`metadata.tar.xz` + `disk.qcow2`), so it can be passed by value
# to the @pinpox/incus service's `localImages` setting. `sshd` and pinpox's
# authorized keys are baked in; `modules` layers extra NixOS config on top.
#
#   pkgs.mkIncusVmImage { }                                  # base: sshd + keys
#   pkgs.mkIncusVmImage { modules = [ ./dev.nix ]; }         # + your config
{
  modules ? [ ],
}:
let
  sys = nixos {
    imports = [
      "${path}/nixos/maintainers/scripts/incus/incus-virtual-machine-image.nix"
    ]
    ++ modules;
    system.stateVersion = lib.mkDefault lib.trivial.release;
    services.openssh.enable = lib.mkDefault true;
    users.users.root.openssh.authorizedKeys.keyFiles = [ pinpox-keys ];

    # cloud-init sets the guest hostname from the Incus instance name
    # (dev-incus `local-hostname`, via the LXD datasource on /dev/lxd/sock)
    # early in boot — before networkd's first DHCP — so the instance
    # registers as <instance-name>.lan instead of the image's baked "nixos".
    # Clear the static hostname so cloud-init's value takes effect; leave
    # networkd rendering to the image (network.enable = false) to avoid
    # clobbering the incus-virtual-machine profile's enp5s0 config.
    networking.hostName = lib.mkForce "";
    services.cloud-init.enable = true;
    services.cloud-init.network.enable = false;

    # nixos-facter CLI for hardware detection inside instances.
    environment.systemPackages = [ nixos-facter ];
  };
  meta = "${sys.config.system.build.metadata}/${sys.config.image.filePath}";
  disk = "${sys.config.system.build.qemuImage}/nixos.qcow2";
in
runCommand "incus-vm-image" { } ''
  mkdir -p $out
  ln -s ${meta} $out/metadata.tar.xz
  ln -s ${disk} $out/disk.qcow2
  # Incus split-image fingerprint = sha256(metadata ‖ rootfs). The import
  # oneshot uses this as a content-addressed idempotency key, so it survives
  # alias renames (same content under a new alias won't re-import/collide).
  cat ${meta} ${disk} | sha256sum | cut -d' ' -f1 > $out/fingerprint
''
