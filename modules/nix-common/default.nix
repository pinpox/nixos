{ config, pkgs, lib, inputs, ... }:
with lib;
let cfg = config.pinpox.defaults.nix;
in {

  options.pinpox.defaults.nix = { enable = mkEnableOption "Nix defaults"; };

  config = mkIf cfg.enable {

    environment.etc."nix/flake_inputs.prom" = {
      mode = "0555";
      text = ''
        # HELP flake_registry_last_modified Last modification date of flake input in unixtime
        # TYPE flake_input_last_modified gauge
        ${concatStringsSep "\n" (map (i:
          ''
            flake_input_last_modified{input="${i}",${
              concatStringsSep "," (mapAttrsToList (n: v: ''${n}="${v}"'')
                (filterAttrs (n: v: (builtins.typeOf v) == "string")
                  inputs."${i}"))
            }} ${toString inputs."${i}".lastModified}'') (attrNames inputs))}
      '';
    };

    # Allow unfree licenced packages
    nixpkgs.config.allowUnfree = true;

    # Enable flakes
    nix = {

      # Save space by hardlinking store files
      autoOptimiseStore = true;

      # Enable flakes
      package = pkgs.nixFlakes;
      extraOptions = ''
        experimental-features = nix-command flakes
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
