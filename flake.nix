{
  description = "My machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # home-manager.url = "github:nix-community/home-manager";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # nixos-home.url = "github:pinpox/nixos-home";
  };

  # outputs = { self, home-manager, nixpkgs }: {
  outputs = { self, nixpkgs, home-manager }:
    let

      defFlakeSystem = baseCfg:
        nixpkgs.lib.nixosSystem {

          system = "x86_64-linux";
          modules = [
            ({ ... }: {
              imports = [
                baseCfg
                home-manager.nixosModules.home-manager
                {
                  #home-manager.useGlobalPkgs = true;
                  home-manager.useUserPackages = true;
                }
              ];
              # Let 'nixos-version --json' know the Git revision of this flake.
              system.configurationRevision =
                nixpkgs.lib.mkIf (self ? rev) self.rev;
              nix.registry.nixpkgs.flake = nixpkgs;
            })
          ];

        };

    in {

      nixosConfigurations = {

        kartoffel = defFlakeSystem {
          imports = [

            ./machines/kartoffel/configuration.nix
            {

              home-manager.users.pinpox = import ./nixos-home/home.nix;

              # home-manager.users.pinpox = {
              #   home.stateVersion = "20.09";
              #   nixpkgs.config.allowUnfree = true;
              # };
            }

            # Include the results of the hardware scan.
            ./machines/kartoffel/hardware-configuration.nix

            # User Profiles
            ./modules/user-profiles/pinpox.nix

            # Modules
            ./modules/bluetooth.nix
            ./modules/borg/home.nix
            ./modules/environment.nix
            ./modules/fonts.nix
            ./modules/locale.nix
            ./modules/lvm-grub.nix
            ./modules/networking.nix
            ./modules/openssh.nix
            ./modules/sound.nix
            ./modules/virtualization.nix
            ./modules/xserver.nix
            ./modules/yubikey.nix
            ./modules/zsh.nix
          ];
        };

        # ahorn = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   modules = [
        #     ./machines/ahorn/configuration.nix

        #     # Include the results of the hardware scan.
        #     ./hardware-configuration.nix

        #     # Default users
        #     ../../modules/user-profiles/pinpox.nix

        #     # Modules
        #     # ../../modules/borg/home.nix
        #     ./modules/bluetooth.nix
        #     ./modules/environment.nix
        #     ./modules/fonts.nix
        #     ./modules/locale.nix
        #     ./modules/lvm-grub.nix
        #     ./modules/networking.nix
        #     ./modules/nix-common.nix
        #     ./modules/openssh.nix
        #     ./modules/sound.nix
        #     ./modules/virtualization.nix
        #     ./modules/wireguard-client.nix
        #     ./modules/xserver.nix
        #     ./modules/yubikey.nix
        #     ./modules/zsh.nix
        #   ];
        # };

        # birne = nixpkgs.lib.nixosSystem {
        #   system = "x86_64-linux";
        #   modules = [

        #     # Machine specific config
        #     ./machines/birne/configuration.nix

        #     # Include the results of the hardware scan.
        #     ./machines/birne/hardware-configuration.nix

        #     # User profiles
        #     ./modules/user-profiles/pinpox.nix

        #     # Modules
        #     ./modules/borg-server.nix
        #     ./modules/dyndns.nix
        #     ./modules/environment.nix
        #     ./modules/locale.nix
        #     ./modules/lvm-grub.nix
        #     ./modules/monit/default.nix
        #     ./modules/openssh.nix
        #     ./modules/zsh.nix
        #     ./modules/borg-monitor-repo.nix
        #   ];
        # };

        #         kfbox = nixpkgs.lib.nixosSystem {
        #           system = "x86_64-linux";
        #           modules = [ ./machines/kfbox/configuration.nix ];
        #         };

        #         mega = nixpkgs.lib.nixosSystem {
        #           system = "x86_64-linux";
        #           modules = [ ./machines/mega/configuration.nix ];
        #         };

        #         porree = nixpkgs.lib.nixosSystem {
        #           system = "x86_64-linux";
        #           modules = [

        #             # User Profiles
        #             ./modules/user-profiles/pinpox.nix

        #             # Modules
        #             ./modules/mmonit.nix
        #             ./modules/monit/default.nix
        #             ./modules/environment.nix
        #             ./modules/locale.nix
        #             ./modules/openssh.nix
        #             ./modules/zsh.nix

        #             # Other machine-specific configuration
        #             ./machines/porree/configuration.nix
        #           ];
        #         };
      };
    };
}
