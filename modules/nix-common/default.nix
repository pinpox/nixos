{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.defaults.nix;
in {

  options.pinpox.defaults.nix = { enable = mkEnableOption "Nix defaults"; };

  config = mkIf cfg.enable {

    # Allow unfree licenced packages
    nixpkgs.config.allowUnfree = true;

    # Enable flakes
    nix = {

      # Save space by hardlinking store files
      autoOptimiseStore = true;

      # Enable flakes
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes ca-references
      '';

      binaryCachePublicKeys =
        [ "cache.lounge.rocks:uXa8UuAEQoKFtU8Om/hq6d7U+HgcrduTVr8Cfl6JuaY=" ];
      binaryCaches =
        [ "https://cache.nixos.org" "https://cache.lounge.rocks?priority=50" ];
      trustedBinaryCaches =
        [ "https://cache.nixos.org" "https://cache.lounge.rocks" ];

      # Clean up old generations after 30 days
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

      # Users allowed to run nix
      allowedUsers = [ "root" ];
    };
  };
}
