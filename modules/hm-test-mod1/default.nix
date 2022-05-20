{ config, pkgs, lib, flake-self, nixpkgs, ... }:
with lib;
let
  cfg = config.pinpox.hm.mod1
    in {

    imports = [ home-manager.nixosModules.home-manager ];

  options.pinpox.hm.mod1 = { enable = mkEnableOption "hm test mod 1"; };

  config = mkIf cfg.enable {


    home-manager.users.pinpox = { };

  };
  }
