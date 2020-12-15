let

  # Basic krops setup
  krops = builtins.fetchGit { url = "https://cgit.krebsco.de/krops/"; };
  lib = import "${krops}/lib";
  pkgs = import "${krops}/pkgs" { };

  # Source is a function that takes `name` as argument and returns the sources
  # for the machine (config and nixpkgs).
  source = name:
    lib.evalSource [{

      # Secrets for the individual machines are copied from password-store.
      # Each machine has a folder containing it's own secrets.
      secrets.pass = {
        dir = toString /home/pinpox/.local/share/password-store/nixos-secrets;
        name = name;
      };

      # Using latest nixpkgs. fetchAlways will ensure that everything is up to
      # date.
      nixpkgs.git = {
        ref = "origin/nixos-unstable";
        fetchAlways = true;
        url = "https://github.com/NixOS/nixpkgs";
      };

      # Copy over the whole repo. By default nixos-rebuild will use the
      # currents system hostname to lookup the right nixos configuration in
      # `nixosConfigurations` from flake.nix
      machine-config.file = toString ../pinpox-nixos;
    }];

  command = targetPath: ''
    nix-shell -p git --run '
      nixos-rebuild switch --flake ${targetPath}/machine-config || \
        nixos-rebuild switch --flake ${targetPath}/machine-config
    '
  '';

  # Define machines with connection parameters and configuration
  ahorn = pkgs.krops.writeCommand "deploy-ahorn" {
    inherit command;
    source = source "ahorn";
    target = "root@192.168.2.100";
  };

  birne = pkgs.krops.writeCommand "deploy-birne" {
    inherit command;
    source = source "birne";
    target = "root@birne.wireguard";
  };

  kartoffel = pkgs.krops.writeCommand "deploy-kartoffel" {
    inherit command;
    source = source "kartoffel";
    target = "root@kartoffel.wireguard";
  };

  kfbox = pkgs.krops.writeCommand "deploy-kfbox" {
    inherit command;
    source = source "kfbox";
    target = "root@kfbox.public";
  };

  mega = pkgs.krops.writeCommand "deploy-mega" {
    inherit command;
    source = source "mega";
    target = "root@mega.public";
  };

  porree = pkgs.krops.writeCommand "deploy-porree" {
    inherit command;
    source = source "porree";
    target = "root@porree.public";
  };

in {

  # Define deployments

  # Individual machines
  ahorn = ahorn;
  birne = birne;
  kartoffel = kartoffel;
  kfbox = kfbox;
  mega = mega;
  porree = porree;

  # Groups
  all = pkgs.writeScript "deploy-all"
    (lib.concatStringsSep "\n" [ ahorn birne kartoffel kfbox mega porree ]);

  servers = pkgs.writeScript "deploy-servers"
    (lib.concatStringsSep "\n" [ birne kfbox mega porree ]);
}

# Run with (e.g.):
# nix-build ./krop.nix -A kartoffel && ./result

# # Define machines with connection parameters and configuration
# ahorn = pkgs.krops.writeCommand "deploy-ahorn" {
#   inherit command;
#   source = source "ahorn";
#   target = "root@ahorn.wireguard";
# };
