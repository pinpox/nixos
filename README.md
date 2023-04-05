![nixos](https://socialify.git.ci/pinpox/nixos/image?description=1&font=Source%20Code%20Pro&forks=1&issues=1&logo=https%3A%2F%2Fpablo.tools%2Fnixoscolorful.svg&owner=1&pattern=Circuit%20Board&pulls=1&stargazers=1&theme=Light)


**Configuration checks:** [![Build Status](https://drone.lounge.rocks/api/badges/pinpox/nixos/status.svg)](https://drone.lounge.rocks/pinpox/nixos)

This repository includes all configurations for my NixOS machines. Feel free to
use parts of it as you please, but keep it mind it is intended mostly for
personal use. I've written posts about certain aspects of this setup on my
[personal blog](https://pablo.tools/posts).

# Initial Setup

The structure of this repository is meant to allow easy manual deployment.
Individual hosts are defined in `/machines/<hostname>` and will import re-usable
parts of the configuration as needed.

Deployment is managed with [lollypops](https://github.com/pinpox/lollypops)
Secrets are stored in [pass](https://www.passwordstore.org/).

**TL;DR** To use a host configuration on a fresh install, make sure that:

- The hostname is set correctly (`hostname <machine name>`)
- You are connected to the internet and have access rights to the repository
- Pass has the necessary secrets for the machine
- The machine's config is up-to-date

Then backup the generated `hardware-configuration.nix` file:

```bash
# Overwrite hardware-configuration.nix file with the generated one
cp /etc/nixos/hardware-configuration.nix \
   ./machines/$(hostname)/hardware-configuration.nix

# Commit and push the new file
git commit -am"Add hardware-configuration for $(hostname)" && git push
```

> TODO: update

It is also possible to build on the system itself when logged in, e.g. to get
additional debug information.

```bash
cd /var/src/machine-config
sudo nixos-rebuild --flake ".#kartoffel" switch
```

# Current Hosts

| Configuration                       | Type      | Location    | VPN IP         | Description                  |
| ----------------------------------- | --------- | ----------- | -------------- | ---------------------------- |
| [kartoffel](./machines/kartoffel)   | Desktop   | local       | `192.168.7.3`  | Desktop                      |
| [ahorn](./machines/ahorn)           | Desktop   | local       | `192.168.7.2`  | Notebook                     |
| [birne](./machines/birne)           | Server    | local       | `192.168.7.4`  | Local NAS                    |
| [porree](./machines/porree)         | Server    | netcup.de   | `192.168.7.1`  | Server for pablo.tools       |
| [mega](./machines/mega)             | Server    | netcup.de   | `192.168.7.6`  | Server for megaclan3000.de   |
| [kfbox](./machines/kfbox)           | Server    | netcup.de   | `192.168.7.5`  | Server for 0cx.de            |

The services running on each host are documented in the host-specific
`README.md` files.

# Deployment

## Default Deployment

Deployment is handled with [lollypops](https://github.com/pinpox/lollypops).

TODO Update/document

## First Deployment

If the system has not been configured to use flakes (e.g. fresh install), the
first deployment will have to be build on a machine that has. This can be done
from any of the other hosts that have the repository. The configuration will the
have the necessary options set, so that flakes works from now on with the normal
lollypops deployment.

```bash
# bash, zsh doesn't always work correctly
sudo nixos-rebuild --flake .#new-hostname --target-host <new-host-ip> --build-host localhost switch
 ```

# Contributing?

While contributions don't make much sense for a personal configuration repository,
I'm always happy to get hints, tips and constructive criticism. If you find something 
that could be done in a better way, please let me know!


<a href="https://www.buymeacoffee.com/pinpox"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=😎&slug=pinpox&button_colour=82aaff&font_colour=000000&font_family=Inter&outline_colour=000000&coffee_colour=FFDD00"></a>
