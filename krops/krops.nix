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
  ahorn = pkgs.krops.writeDeploy "deploy-ahorn" {
    source = source "ahorn";
    target = "root@ahorn";
  };

  birne = pkgs.krops.writeDeploy "deploy-birne" {
    source = source "birne";
    target = "root@birne";
  };

  kartoffel = pkgs.krops.writeDeploy "deploy-kartoffel" {
    source = source "kartoffel";
    target = "root@kartoffel";
  };

  kfbox = pkgs.krops.writeDeploy "deploy-kfbox" {
    source = source "kfbox";
    target = "root@kfbox";
  };

  mega = pkgs.krops.writeDeploy "deploy-mega" {
    source = source "mega";
    target = "root@mega";
  };

  porree = pkgs.krops.writeDeploy "deploy-porree" {
    source = source "porree";
    target = "root@porree";
  };

in {

  # Define deployments

  # Individual machines
  ahorn = ahorn;
  birne = birne;
  kartoffel = kartoffel;
  kfbox = kfbox;
  mega = mega;
  porre = porree;

  # Groups
  all = pkgs.writeScript "deploy-all"
    (lib.concatStringsSep "\n" [ ahorn birne kartoffel kfbox mega porree ]);

  servers = pkgs.writeScript "deploy-servers"
    (lib.concatStringsSep "\n" [ birne kfbox mega porree ]);
}

# Run with (e.g.):
# nix-build ./krop.nix -A kartoffel && ./result
