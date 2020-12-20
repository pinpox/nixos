{ config, pkgs, lib, ... }: {

  nixpkgs.config.packageOverrides = pkgs: rec {
    mmonit = pkgs.callPackage ../packages/mmonit {};
  };

  environment.systemPackages = with pkgs; [ mmonit ];
}
