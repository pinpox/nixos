![nixos](https://socialify.git.ci/pinpox/nixos/image?description=1&font=Source%20Code%20Pro&forks=1&issues=1&logo=https%3A%2F%2Fpablo.tools%2Fnixoscolorful.svg&owner=1&pattern=Circuit%20Board&pulls=1&stargazers=1&theme=Light)

This repository includes all configurations for my NixOS machines. Feel free to
use parts of it as you please, but keep it mind it is intended mostly for
personal use. I've written posts about certain aspects of this setup on my
[personal blog](https://pablo.tools/blog).

# Intial Setup

The structure of this repository is meant to allow easy manual deployment.
Individual hosts are defined in `/machines/<hostname>` and will import re-usable
parts of the configuration as needed.

**TL;DR** To use a host configuration on a fresh install, do as root:
```bash
# Backup generated configuration files
mv /etc/nixos /etc/nixos-old

# Clone repository to /var/nixos-configs
git clone git@github.com:pinpox/nixos.git /etc/nixos

# Overwrite hardware-configuration.nix file with the generated one
mv /etc/nixos-old/hardware-configuration.nix \
   /etc/nixos/machines/$(hostname)/hardware-configuration.nix

# Link the machines configuration.nix to the root, so nixos-rebuild finds it
sudo ln -sr /etc/nixos/machines/$(hostname)/configuration.nix /etc/nixos/configuration.nix
```

The proceed to set up the unmanaged resources as described below.


# Current Hosts

| Configuration                       | Type      | Location    | VPN IP         | Description                  |
| ----------------------------------- | --------- | ----------- | -------------- | ---------------------------- |
| [kartoffel](./machines/kartoffel)   | Desktop   | local       | `192.168.7.2`  | Desktop                      |
| [ahorn](./machines/ahorn)           | Desktop   | local       | `192.168.7.99` | Notebook                     |
| [birne](./machines/birne)           | Server    | local       | `192.168.7.6`  | Local NAS                    |
| [porree](./machines/porree)         | Server    | netcup.de   | `192.168.7.1`  | Server for pablo.tools       |
| [mega](./machines/mega)             | Server    | netcup.de   |                | Server for megaclan3000.de   |
| [kfbox](./machines/kfbox)           | Server    | netcup.de   |                | Server for 0cx.de            |

The services running on each host are documented in the host-specific
`README.md` files.

# Unmanaged Resources

The following resources are not managed or included in this repository and will
have to be put in place manually.

## `/secrets` Directory

The `/secrets` directory contains all sensitive files that should not be shared
or put into the nix-store. It has to be created/placed manually. Make sure the
permissions on `/secerts` directory are set to `600` **recursively** and it is
owned `root:root`.

``` bash
# Set permissions owner and group
chmod -R 600 /secrets
chown root:root -R /secrets
```

Example layout of expected structure as used by this configuration:

```
 secrets
└──  hostname
   ├──  borg
   │  └──  repo-passphrase
   ├──  ssh
   │  ├──  key-backup-private
   │  ├──  key-backup-public
   │  ├──  key-root-private
   │  └──  key-root-public
   └──  wireguard
      ├──  private
      └──  public
```

## Home-manager configuration

User-specific configuration is installed by home-manager where needed. Setup for
the `pinpox` user is hosted in a [separate
repository](https://github.com/pinpox/nixos-home) so it can be used
independently.

# Creating new Hosts

The following describes how to create new hosts to be included in this project
structure. It assumes a working NixOS installation on a new machine. The
following steps further assume you are logged in as root (e.g. via SSH)

## Preliminary Checks

- Check that hostname is set
- Check machine is connected to the internet
- Check timezone is correct
- Check nix-channel is correct

## Create Secrets

The following will create a new set of keys to be added to the `/secrets`
directory of this host.

```bash

# Create directories
mkdir -p /secrets/$(hostname)/{borg,wireguard,ssh}

# Create SSH keys
ssh-keygen -t ed25519 -f /secrets/$(hostname)/ssh/id_ed25519

# Create wireguard keys
# Use if `wireguard` is not installed: nix-shell -p pkgs.wireguard
wg genkey > /secrets/$(hostname)/wireguard/privatekey
wg pubkey < /secrets/$(hostname)/wireguard/privatekey > /secrets/$(hostname)/wireguard/publickey

# Create borg passphrase
# Use if `pwgen` is not installed: nix-shell -p pkgs.pwgen
pwgen 20 > /secrets/$(hostname)/borg/repo-passphrase

# Set permissions owner and group
chmod -R 600 /secrets
chown root:root -R /secrets
```

Backup the generated secrets **now**!

## Add GitHub deployment key

The easiest way to get the repository is to add root's SSH key as deployment key
in this repository.

```bash
cat /secrets/$(hostname)/ssh/id_ed25519
```

[Add the key here]( https://github.com/pinpox/nixos/settings/keys/new)

## Copy initial configuration files

```bash
# Use generated key from /secrets while it's not yet put in place
export GIT_SSH_COMMAND='ssh -i /secrets/$(hostname)/ssh/id_ed25519 -o IdentitiesOnly=yes'
# Backup generated configuration files
mv /etc/nixos /etc/nixos-old

# Clone this repository to /etc/nixos
GIT_SSH_COMMAND='ssh -i /secrets/$(hostname)/ssh/id_ed25519 -o IdentitiesOnly=yes' \
   git clone git@github.com:pinpox/nixos.git /etc/nixos

# Save initial configuration.nix and hardware-configuration.nix
cp /etc/nixos-old/*.nix \
   /etc/nixos/machines/$(hostname)/

# Link the machines configuration.nix to the root, so nixos-rebuild finds it
sudo ln -sr /etc/nixos/machines/$(hostname)/configuration.nix /etc/nixos/configuration.nix

```

Machine should run `nixos-rebuild switch` without any problems.  At this point:
**add/commit/push** the changes!


# TODO
- Setup backup
- Setup VPN
- read wireguard public key from /secrets in configuration.nix and sperate to
	/common
- setup root git account in configuration.nix
```
  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"
```

