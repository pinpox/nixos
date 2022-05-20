{ config
, pkgs
, lib
, nur
, flake-self
, wallpaper-generator
, dotfiles-awesome
, home-manager
, ...
}:
with lib;
let cfg = config.pinpox.defaults.home-manager;
in
{

  options.pinpox.defaults.home-manager = {
    enable = mkEnableOption "home-manager configuration";

    profile = mkOption {
      type = types.str;
      default = "server";
      description = "Profile to use";
      example = "desktop";
    };

    username = mkOption {
      type = types.str;
      default = "pinpox";
      description = "Main user";
      example = "lisa";
    };
  };

  imports = [ flake-self.inputs.home-manager.nixosModules.home-manager ];

  config = mkIf cfg.enable {

    # DON'T set useGlobalPackages! It's not necessary in newer
    # home-manager versions and does not work with configs using
    # nixpkgs.config`
    home-manager.useUserPackages = true;

    # Pass all flake inputs to home-manager modules aswell so we can use them
    # there.
    # home-manager.extraSpecialArgs = flake-self.inputs;
    home-manager.extraSpecialArgs = {
      inherit wallpaper-generator dotfiles-awesome;
    };


    nixpkgs.overlays = [ nur.overlay ];

    home-manager.users."${cfg.username}" = {

      imports = [
        {
          nixpkgs.overlays = [
            flake-self.overlays.default
            nur.overlay
            # inputs.neovim-nightly.overlay
          ];
        }
        ./profiles/${cfg.profile}.nix
      ];
    };
  };
}
