---
name: incus-testing
description: Spin up throwaway NixOS VMs on the mango Incus host to test NixOS modules, configs, and multi-machine setups. Use when you need a real booting NixOS system to validate changes beyond `nix build`/eval.
---

Incus runs on **mango** (the only clan host with `/dev/kvm`). From any clan
machine with the `incus` client it's the remote `mango:`; on **kiwi** it is
already the **default remote**, so commands need no prefix there. Instances are
full NixOS VMs — use them to boot a config and check real runtime behaviour
(services start, units, networking, multi-VM interaction) that `nix build` and
`nixos-rebuild build-vm` can't cover well.

## The base image

Alias **`default`** (same image also aliased `nixos-unstable-cloud-init`):
NixOS unstable, **VM-only** (qcow2), with `sshd` + pinpox's SSH keys and
cloud-init baked in. cloud-init sets the guest hostname from the **instance
name**, so a VM named `foo` becomes `foo.lan` (your router does DHCP + DNS on
the macvlan LAN).

## Launch / lifecycle

```bash
incus launch default foo        # create + start. No --vm (image is VM-only),
                                # no mango: prefix on kiwi (default remote).
incus list                      # STATE + IPv4 (192.168.101.x once booted)
incus stop foo                  # --force to hard-stop
incus start foo
incus restart foo
incus delete -f foo             # remove (always clean up test VMs)
```

Give it a few seconds after launch: it boots, cloud-init sets the hostname, then
it pulls a DHCP lease before `foo.lan` resolves. Watch `incus list` for the IP.
Use a **distinct name per VM** — the name is the hostname, so reused names
collide on the router.

## Getting in

```bash
incus exec foo -- bash          # PRIMARY: shell via the incus agent.
                                # No network/auth needed — always works.
ssh root@foo.lan                # key-based (your key is baked in), once booted
```

**Do not rely on console password login** (`incus console foo`): cloud-init
locks root's password, so the "log in with empty password" banner is stale and
fails. Use `incus exec` or SSH.

## Testing a NixOS module or config

**A. In-place rebuild (fastest for iterating on one module).** The image ships
an editable `/etc/nixos/configuration.nix` (plus `incus.nix` for the hostname).
Push your module in and rebuild inside the guest:

```bash
incus file push ./mymodule.nix foo/etc/nixos/mymodule.nix
# import it: add  ./mymodule.nix  to imports in /etc/nixos/configuration.nix
incus exec foo -- sed -i 's#\./incus.nix#& ./mymodule.nix#' /etc/nixos/configuration.nix
incus exec foo -- nixos-rebuild switch
# then check it:
incus exec foo -- systemctl status my-service
incus exec foo -- journalctl -u my-service -b --no-pager
```

**B. Bake into a custom image (reproducible, best for a fixed test target).**
Build an image from this flake with your module layered on the base:

```nix
# flake.nix packages.<system>, next to incus-nixos-unstable-cloud-init
incus-test = mkIncusVmImage { modules = [ ./path/to/mymodule.nix ]; };
```
Then import + launch it (see the @pinpox/incus module's `localImages` for the
declarative import, or import ad-hoc):
```bash
img=$(nix build .#packages.x86_64-linux.incus-test --no-link --print-out-paths)
# on mango (nix copy the closure there first if building elsewhere):
incus image import "$img/metadata.tar.xz" "$img/disk.qcow2" --alias test --reuse
incus launch test foo
```

**C. Deploy a full flake machine config over SSH.** Since VMs are reachable at
`foo.lan` with your key, push a real config with remote rebuild:
```bash
nixos-rebuild switch --target-host root@foo.lan --flake .#<machine>
```
Use this to test an actual machine definition end to end.

## Iterating with snapshots

Snapshot a known-good state, try a change, roll back on failure:

```bash
incus snapshot create foo clean
# ...break things, test...
incus snapshot restore foo clean
incus snapshot list foo
```

## Getting results out

```bash
incus file pull foo/var/log/whatever ./whatever.log
incus exec foo -- cat /etc/some-generated-file
```

## Gotchas

- **No `--vm` needed** — the base image is VM-only, Incus infers the type. (You
  only need `--vm`/`--type` for dual-variant images like `images:debian/12`.)
- **`incus exec` runs on mango's side**, so `$(...)` in a double-quoted remote
  command expands on mango, not the guest. Wrap guest logic in
  `incus exec foo -- sh -lc '...'` with single quotes.
- **Instances are copies of the image** — rebuilding/re-importing the base
  image does not change running VMs. Relaunch to pick up a new base.
- **cloud-init on NixOS only sets the hostname** — it does not install packages
  (`packages:` is a no-op on NixOS). Put packages in the module (method A/B).
- Always **`incus delete -f`** test VMs when done; they hold a LAN lease and a
  storage volume.

## When NOT to use this

For a pure module unit-test that doesn't need a booting system, prefer
`nix build .#nixosConfigurations.<m>.config.system.build.toplevel` or a NixOS
VM test (`nixos-rebuild build-vm`). Reach for Incus when you need a persistent,
LAN-reachable VM, multiple interacting VMs, or to exercise real
networking/services on mango.
