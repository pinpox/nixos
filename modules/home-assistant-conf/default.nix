{ config, pkgs, lib, home-manager, ... }:
with lib;
let cfg = config.pinpox.defaults.home-config;
in {

  options.pinpox.defaults.home-config = {

    profile = mkOption {
      type = types.enum [ "desktop" "server" ];
      # default = "0.0.0.0";
      # example = "192.168.7.1/24";
      # description = ''
      #   IP address of the host.
      #   Make sure to also set the peer entry for the server accordingly.
      # '';
    };

    enable = mkEnableOption "User home configuration";

  };

  imports = mkIf cfg.enable [

    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      # home-manager.users.jdoe = import ./home.nix;

      home-manager.users.pinpox = {


# imports = [ ] ++ lib.optional (builtins.pathExists ./secrets.nix) ./secrets.nix;
        imports = [
          dotfiles-awesome.nixosModules.dotfiles
          {
            nixpkgs.overlays = [
              flake-self.overlays.default
              nur.overlay
                # inputs.neovim-nightly.overlay
              ];
            }
          ]

        ++ lib.optional (cfg.profile == "desktop")  ../../home-manager/home.nix
        ++ lib.optional (cfg.profile == "server")  ../../home-manager/home-server.nix ;

      };
    }

  ];

  config = mkIf cfg.enable {

    # fonts = { };
  };
}
