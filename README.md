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

| Configuration                       | Type      | Location    | VPN IP | Description                  |
| ----------------------------------- | --------- | ----------- | ------ | ---------------------------- |
| [ahorn](./machines/ahorn)           | Desktop   | local       | `192.168.7.X` | Notebook                     |
| [birne](./machines/birne)           | Server    | local       | `192.168.7.X` | Local NAS                    |
| [kartoffel](./machines/kartoffel)   | Desktop   | local       | `192.168.7.2` | Desktop                      |
| [kfbox](./machines/kfbox)           | Server    | netcup.de   | `192.168.7.X` | Server for 0cx.de            |
| [mega](./machines/mega)             | Server    | netcup.de   | `192.168.7.X` | Server for megaclan3000.de   |
| [porree](./machines/porree)         | Server    | netcup.de   | `192.168.7.X` | Personal Server              |

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
chwon root:root -R /secrets
```

Example layout of expected structure as used by this configuration:

```
 secrets
└──  hostname
   ├──  borg
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

# Creating new Hosts (TODO)
- Backup generated hardware-configuration
- Create and register/include keys
https://github.com/pinpox/nixos/settings/keys
- Setup backup
- Setup VPN

