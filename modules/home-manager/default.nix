{ config
, pkgs
, lib
, nur
, flake-self
, home-manager
, dotfiles-awesome
, wallpaper-generator
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

  imports = [ home-manager.nixosModules.home-manager ];

  config = mkIf cfg.enable {

    # DON'T set useGlobalPackages! It's not necessary in newer
    # home-manager versions and does not work with configs using
    # nixpkgs.config`
    home-manager.useUserPackages = true;

    # Pass all flake inputs that are neeeded in modules here after adding them
    # to the arguments of this module in the first line of this file.
    home-manager.extraSpecialArgs = {
      inherit dotfiles-awesome wallpaper-generator;
    };


    # home-manager.extraSpecialArgs = config._module.args;

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
