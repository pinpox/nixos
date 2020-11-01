# NixOS

This repository includes all configurations for my NixOS machines. Feel free to
use parts of it as you please, but keep it mind it is intended mostly for
personal use.

# Setup host after NixOS installation

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
 secrets-example
├──  kartoffel
│  ├──  borg
│  ├──  ssh
│  │  ├──  key-backup-private
│  │  ├──  key-backup-public
│  │  ├──  key-root-private
│  │  └──  key-root-public
│  └──  wireguard
│     ├──  private
│     └──  public
└──  porree
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
