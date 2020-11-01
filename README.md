![nixos](https://socialify.git.ci/pinpox/nixos/image?description=1&descriptionEditable=My%20NixOS%20Configurations&font=Source%20Code%20Pro&forks=1&issues=1&logo=https%3A%2F%2Fpablo.tools%2Fnixoscolorful.svg&owner=1&pattern=Circuit%20Board&pulls=1&stargazers=1&theme=Light)

This repository includes all configurations for my NixOS machines. Feel free to
use parts of it as you please, but keep it mind it is intended mostly for
personal use.

# Intial Setup

The structure of this repository is meant to allow easy manual deployment.
Individual hosts are defined in `/machines/<hostname>` and will import
re-usable parts of the configuration as needed. 

**TL;DR** To use a host configuration on a fresh install, do as root:
```bash
# Add the root SSH key as deployment key to the GitHub repostory
# If root has no key yet, generate one with `ssh-keygen`
# https://github.com/pinpox/nixos/settings/keys

# Clone repository to /var/nixos-configs
git clone git@github.com:pinpox/nixos.git /var/nixos-configs

# Link desired host configuration to /etc/nixos
ln -s /var/nixos-configs/machines/kartoffel /etc/nixos
```

The proceed to set up the unmanaged resources as described below.


# Current Hosts

| Configuration                       | Type      | Location    | VPN IP | Description                  |
| ----------------------------------- | --------- | ----------- | ------ | ---------------------------- |
| [ahorn](./machines/ahorn)           | Desktop   | local       | `192.168.7.X` | Notebook                     |
| [birne](./machines/birne)           | Server    | local       | `192.168.7.X` | Local NAS                    |
| [kartoffel](./machines/kartoffel)   | Desktop   | local       | `192.168.7.X` | Desktop                      |
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
or put into the nix-store. It has to be created/placed manuall.

**Important**: Make sure the permissions on `/secerts` directory are set to
`600` **recursively** and it is owned `root:root`.

``` bash
# Set permissions
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

# TODO Creating new Hosts
- Create and register/include keys
- Setup backup
- Setup VPN
