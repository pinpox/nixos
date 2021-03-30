{
  description = "My machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # nixpkgs-pinned.url =
    #   "github:nixos/nixpkgs/c4d27d698a5925b94715ae8972d215e033023cd9";
    nixpkgs-pinned.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-home.url = "github:pinpox/nixos-home";
    nixos-home.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, ... }@inputs:
    with inputs;
    let
      # Function to create default (common) system config options
      defFlakeSystem = baseCfg:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [

            ({ ... }: {
              imports = builtins.attrValues self.nixosModules ++ [
                {
                  # Set the $NIX_PATH entry for nixpkgs. This is necessary in
                  # this setup with flakes, otherwise commands like `nix-shell
                  # -p pkgs.htop` will keep using an old version of nixpkgs.
                  # With this entry in $NIX_PATH it is possible (and
                  # recommended) to remove the `nixos` channel for both users
                  # and root e.g. `nix-channel --remove nixos`. `nix-channel
                  # --list` should be empty for all users afterwards
                  nix.nixPath = [ "nixpkgs=${nixpkgs}" ];

                  # DONT set useGlobalPackages! It's not necessary in newer
                  # home-manager versions and does not work with configs using
                  # `nixpkgs.config`
                  home-manager.useUserPackages = true;
                }
                baseCfg
                home-manager.nixosModules.home-manager
              ];

              # Let 'nixos-version --json' know the Git revision of this flake.
              system.configurationRevision =
                nixpkgs.lib.mkIf (self ? rev) self.rev;
              nix.registry.nixpkgs.flake = nixpkgs;
            })
          ];
        };

      base-modules-server = [
        ./users/pinpox.nix
        {
          home-manager.users.pinpox = nixos-home.nixosModules.server;

          # pinpox.metrics.node.enable = true;
          pinpox.defaults = {
            environment.enable = true;
            locale.enable = true;
            nix.enable = true;
            zsh.enable = true;
            networking.enable = true;
          };
          pinpox.services = { openssh.enable = true; };
        }
      ];

    in {

      # Output all modules in ./modules to flake. Modules should be in
      # individual subdirectories and contain a default.nix file
      nixosModules = builtins.listToAttrs (map (x: {
        name = x;
        value = import (./modules + "/${x}");
      }) (builtins.attrNames (builtins.readDir ./modules)));

      nixosConfigurations = {

        kartoffel = defFlakeSystem {
          imports = [
            ./machines/kartoffel/configuration.nix
            { pinpox.desktop.homeConfig = nixos-home.nixosModules.desktop; }
          ];
        };

        ahorn = defFlakeSystem {
          imports = [
            ./machines/ahorn/configuration.nix
            { pinpox.desktop.homeConfig = nixos-home.nixosModules.desktop; }
          ];
        };

        birne = defFlakeSystem {
          imports = base-modules-server ++ [
            ./machines/birne/configuration.nix
          ];
        };

        bob = defFlakeSystem {
          imports = base-modules-server ++ [
            ./machines/bob/configuration.nix
          ];
        };

        kfbox = defFlakeSystem {
          imports = base-modules-server ++ [
            ./machines/kfbox/configuration.nix
          ];
        };

        porree = defFlakeSystem {
          imports = base-modules-server
            ++ [ ./machines/porree/configuration.nix ];
        };

        # mega = defFlakeSystem {
        #   imports = base-modules-server
        #     ++ [ ./machines/mega/configuration.nix ];
        # };
      };
    };
}
