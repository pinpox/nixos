![nixos](https://socialify.git.ci/pinpox/nixos/image?description=1&descriptionEditable=My%20NixOS%20Configurations&font=Source%20Code%20Pro&forks=1&issues=1&logo=https%3A%2F%2Fpablo.tools%2Fnixoscolorful.svg&owner=1&pattern=Circuit%20Board&pulls=1&stargazers=1&theme=Light)

This repository includes all configurations for my NixOS machines. Feel free to
use parts of it as you please, but keep it mind it is intended mostly for
personal use.

# Intial Setup

The structure of this repository is meant to allow easy manual deployment.
Individual hosts are defined in `/machines/<hostname>` and will import
re-usable parts of the configuration as needed. 

**TL;DR** To use a host configuration on a fresh install, do as root:
```
# If the root user has no key yet, generate one
ssh-keygen

# Add key as deployment key to the GitHub repostory
# https://github.com/pinpox/nixos/settings/keys

# Clone repository to /var/nixos-configs
git clone git@github.com:pinpox/nixos.git /var/nixos-configs

# Link desired host configuration to /etc/nixos
ln -s /var/nixos-configs/machines/kartoffel /etc/nixos
```

# Create new Machine

TODO
- Create and register keys
- Setup backup
- Setup VPN

# Machines and Services



## porree (netcup.de)
- VPN server (wireguard)
- hugo-website
- lislon-website
- bitwarden_rs
- gitea
- netdata

## birne (local)
- backup-server
- seafile
- netdata

## kfbox (netcup.de)

## megaclan3000.de




# External

## Secrets in `/secrets`
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
