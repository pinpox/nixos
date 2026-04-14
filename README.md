![nixos](https://socialify.git.ci/pinpox/nixos/image?description=1&font=Source%20Code%20Pro&forks=1&issues=1&logo=https%3A%2F%2Fpablo.tools%2Fnixoscolorful.svg&owner=1&pattern=Circuit%20Board&pulls=1&stargazers=1&theme=Light)

**Configuration checks:** [![Build Status](https://build.lounge.rocks/api/badges/9/status.svg)](https://build.lounge.rocks/repos/9)

All Module options are documented at: https://pinpox.github.io/nixos/

This repository includes all configurations for my NixOS machines. Feel free to
use parts of it as you please, but keep it mind it is intended mostly for
personal use. I've written posts about certain aspects of this setup on my
[personal blog](https://pablo.tools/posts).

# Overview

The structure of this repository is meant to allow easy manual deployment while
being [clan](https://clan.lol) compatible. Individual hosts are defined in
`/machines/<hostname>` and import re-usable parts of the configuration as
needed. Deployment and management is done with [clan](https://clan.lol), and
secrets are stored in [passage](https://github.com/FiloSottile/passage), which
uses age for encryption.

The current hosts are:

| Configuration                     | Type    | Location  | Description                          |
| --------------------------------- | ------- | --------- | ------------------------------------ |
| [kartoffel](./machines/kartoffel) | Desktop | local     | Main desktop workstation             |
| [kiwi](./machines/kiwi)           | Laptop  | local     | Framework 13 (AMD AI 300 series)     |
| [limette](./machines/limette)     | Laptop  | local     | Notebook                             |
| [fichte](./machines/fichte)       | Laptop  | local     | ThinkPad T490                        |
| [tanne](./machines/tanne)         | Laptop  | local     | ThinkPad T480s                       |
| [uconsole](./machines/uconsole)   | Handheld| local     | Clockwork uConsole (RPi CM4)         |
| [birne](./machines/birne)         | Server  | local     | Local NAS                            |
| [porree](./machines/porree)       | Server  | netcup.de | Server for pablo.tools               |
| [kfbox](./machines/kfbox)         | Server  | netcup.de | Server for 0cx.de                    |
| [clementine](./machines/clementine) | Server | netcup.de | Server for megaclan3000.de           |
| [traube](./machines/traube)       | Server  | local     | aarch64 server                       |

# Deployment

Deployment is done via [clan CLI](https://clan.lol) provided via the flake's
default nix shell. I use [direnv](https://direnv.net/) to automatically start it
when entering the repository's directory. Run `direnv allow` on the first time,
after that, deployment can be done via:

```sh
clan machines update <hostname>
```

## Repository Organization

The configuration is organized as follows:

- `machines/<hostname>`: Host-specific configurations
- `modules`: System-level NixOS modules
- `home-manager/modules`: User-level home-manager modules for specific applications
- `home-manager/profiles`: Profiles that combine multiple home-manager modules
- `home-manager/packages`: Custom packages for applications not present in nixpkgs
- `clan-service-modules`: [Clan](https://clan.lol) services

# Contributing?

While contributions don't make much sense for a personal configuration repository,
I'm always happy to get hints, tips and constructive criticism. If you find something
that could be done in a better way, please let me know!

<a href="https://www.buymeacoffee.com/pinpox"><img src="https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=&slug=pinpox&button_colour=82aaff&font_colour=000000&font_family=Inter&outline_colour=000000&coffee_colour=FFDD00" alt="Buy Me A Coffee"></a>
