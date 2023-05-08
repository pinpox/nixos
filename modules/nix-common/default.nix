{ config, pkgs, lib, flake-self, nixpkgs, ... }:
with lib;
let cfg = config.pinpox.defaults.nix;
in
{

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
                  flake-self.inputs."${i}"))
                }} ${ toString flake-self.inputs."${i}".lastModified or 0 }'')
          (attrNames flake-self.inputs))}
      '';
    };

    # Set the $NIX_PATH entry for nixpkgs. This is necessary in
    # this setup with flakes, otherwise commands like `nix-shell
    # -p pkgs.htop` will keep using an old version of nixpkgs.
    # With this entry in $NIX_PATH it is possible (and
    # recommended) to remove the `nixos` channel for both users
    # and root e.g. `nix-channel --remove nixos`. `nix-channel
    # --list` should be empty for all users afterwards
    nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
    nixpkgs.overlays = [ flake-self.overlays.default ];

    # Let 'nixos-version --json' know the Git revision of this flake.
    system.configurationRevision =
      nixpkgs.lib.mkIf (flake-self ? rev) flake-self.rev;
    nix.registry.nixpkgs.flake = nixpkgs;
    nix.registry.pinpox.flake = flake-self;

    # Allow unfree licenced packages
    nixpkgs.config.allowUnfree = true;

    lollypops.secrets.files."nix/nix-access-tokens" = { };

    # Enable flakes
    nix = {

      # Enable flakes
      package = pkgs.nixVersions.stable;
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
      # !include ${config.lollypops.secrets.files."nix/nix-access-tokens".path}

      settings = {

        trusted-public-keys =
          [ "cache.lounge.rocks:uXa8UuAEQoKFtU8Om/hq6d7U+HgcrduTVr8Cfl6JuaY=" ];

        substituters = [
          "https://cache.nixos.org"
          "https://cache.lounge.rocks?priority=50"
        ];

        trusted-substituters =
          [ "https://cache.nixos.org" "https://cache.lounge.rocks" ];

        # Save space by hardlinking store files
        auto-optimise-store = true;

        # Users allowed to run nix
        allowed-users = [ "root" ];
      };

      # Clean up old generations after 30 days
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
  };
}
