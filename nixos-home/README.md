![nixos-home](https://socialify.git.ci/pinpox/nixos-home/image?description=1&descriptionEditable=My%20home-manager%20%24USER%20setup&font=Source%20Code%20Pro&forks=1&issues=1&logo=https%3A%2F%2Fpablo.tools%2Fimg%2Favatar.gif&owner=1&pattern=Circuit%20Board&pulls=1&stargazers=1&theme=Light)

My user setup for [NixOS](https://nixos.org) Desktops.  System configuration is in a
[separate repository](https://github.com/pinpox/nixos).  Visit
[pablo.tools](https://pablo.tools/blog) for details.

## Setup

The following steps are assumed to be taken as the user for which the
configuration should be set up.

### Install home-manager

Install home-manager for unstable channel and removed generated config.

```bash
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
rm .config/nixpkgs/home.nix
```

### Install configuration

Since SSH-keys may not be present and my yubikey is not set up yet, use HTTPS to
clone the configuration instead of SSH.

```bash
# Move generated configuration out of the way
mv ~/.config/nixpkgs .config/nixpkgs-old

# Clone repository to correct location
git clone https://github.com/pinpox/nixos-home.git ~/.config/nixpkgs
```

### Rebuild

Run:

```bash

# For desktops
home-manager switch

# For servers (no GUI)
home-manager  -f .config/nixpkgs/home-server.nix switch
```

If everything went well, log out and back in. Consider changing the remote of
the configuation repository to use SSH now instead of HTTPS.

```bash
cd ~/.config/nixpkgs
git remote set-url origin git@github.com:pinpox/nixos-home.git
```

# TODO 

- generate ~/.xinitrc
```
exec ~/.hm-xsession
```

