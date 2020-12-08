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

      # Name is interpolated to get the correct configuration.nix file
      nixos-config.file = toString ../machines + "/${name}/configuration.nix";

      # Import common modules
      common.file = toString ../common;
    }];

    # Define machines with connection parameters and configuration
  kartoffel = pkgs.krops.writeDeploy "deploy-kartoffel" {
    source = source "kartoffel";
    target = "root@localhost";
  };

  porree = pkgs.krops.writeDeploy "deploy-porree" {
    source = source "porree";
    target = "root@nix.own";
  };

in {

  # Define deployments. This can be a single machine or a group like "servers".

  # TODO
  # ahorn
  # birne
  # mega
  # kfbox

  # Individual machines
  kartoffel = kartoffel;
  porre = porree;

  # Groups
  all = pkgs.writeScript "deploy-all"
    (lib.concatStringsSep "\n" [ kartoffel porree ]);
}

# Run with (e.g.):
# nix-build ./krop.nix -A kartoffel && ./result
