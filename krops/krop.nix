let
  krops = builtins.fetchGit { url = "https://cgit.krebsco.de/krops/"; };
  lib = import "${krops}/lib";
  pkgs = import "${krops}/pkgs" { };

  source = name:
    lib.evalSource [{
      secrets.pass = {
        dir = toString /home/pinpox/.local/share/password-store/nixos-secrets;
        name = name;
      };

      nixpkgs.git = {
        ref = "origin/nixos-unstable";
        fetchAlways = true;
        url = "https://github.com/NixOS/nixpkgs";
      };

      nixos-config.file = toString ../machines + "/${name}/configuration.nix";
      common.file = toString ../common;
    }];

  kartoffel = pkgs.krops.writeDeploy "deploy-kartoffel" {
    source = source "kartoffel";
    target = "root@localhost";
  };

  porree = pkgs.krops.writeDeploy "deploy-porree" {
    source = source "porree";
    target = "root@nix.own";
  };

in {

  kartoffel = kartoffel;
  porre = porree;

  all = pkgs.writeScript "deploy-all"
    (lib.concatStringsSep "\n" [ kartoffel porree ]);
}
