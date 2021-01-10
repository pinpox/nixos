{
  description = "My machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nixos-home.url = "github:pinpox/nixos-home";
    nixos-home.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, home-manager, nixos-home }:
    let
      # Function to create defult (common) system config options
      defFlakeSystem = baseCfg:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            # Add home-manager option to all configs
            ({ ... }: {
              imports = [
                {
                  nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
                }
                baseCfg
                home-manager.nixosModules.home-manager
                # DONT set useGlobalPackages! It's not necessary in newer
                # home-manager versions and does not work with configs using
                # `nixpkgs.config`
                { home-manager.useUserPackages = true; }
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
            # Machine-specific
            ./machines/kartoffel/configuration.nix

            # Include the results of the hardware scan.
            ./machines/kartoffel/hardware-configuration.nix

            # User profiles
            ./modules/user-profiles/pinpox.nix
            # Add home-manager config
            { home-manager.users.pinpox = nixos-home.nixosModules.desktop; }

            # Modules
            ./modules/bluetooth.nix
            ./modules/borg/home.nix
            ./modules/environment.nix
            # ./modules/fonts.nix
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

        ahorn = defFlakeSystem {
          imports = [
            # Machine-specific
            ./machines/ahorn/configuration.nix

            # Include the results of the hardware scan.
            ./hardware-configuration.nix

            # User profiles
            ./modules/user-profiles/pinpox.nix
            # Add home-manager config
            {
              home-manager.users.pinpox = nixos-home.nixosModules.desktop;
            }

            # Modules
            # ../../modules/borg/home.nix
            ./modules/bluetooth.nix
            ./modules/environment.nix
            # ./modules/fonts.nix
            ./modules/locale.nix
            ./modules/lvm-grub.nix
            ./modules/networking.nix
            ./modules/nix-common.nix
            ./modules/openssh.nix
            ./modules/sound.nix
            ./modules/virtualization.nix
            ./modules/wireguard-client.nix
            ./modules/xserver.nix
            ./modules/yubikey.nix
            ./modules/zsh.nix
          ];
        };

        birne = defFlakeSystem {
          imports = [

            # Machine specific config
            ./machines/birne/configuration.nix

            # Include the results of the hardware scan.
            ./machines/birne/hardware-configuration.nix

            # User profiles
            ./modules/user-profiles/pinpox.nix
            # Add home-manager config
            {
              home-manager.users.pinpox = nixos-home.nixosModules.server;
            }

            # Modules
            ./modules/borg-server.nix
            ./modules/dyndns.nix
            ./modules/environment.nix
            ./modules/locale.nix
            ./modules/lvm-grub.nix
            ./modules/monit/default.nix

            ./modules/openssh.nix
            ./modules/zsh.nix
            ./modules/borg-monitor-repo.nix
          ];
        };

        kfbox =
          defFlakeSystem { imports = [ ./machines/kfbox/configuration.nix ]; };

        mega =
          defFlakeSystem { imports = [ ./machines/mega/configuration.nix ]; };

        # home-assistant = defFlakeSystem {
        #   # Other system types could be sepcified here, e.g.:
        #   # system = "x86_64-linux";
        #   imports = [ ./machines/home-assistant/configuration.nix ];
        # };

        porree = defFlakeSystem {
          imports = [

            # User profiles
            ./modules/user-profiles/pinpox.nix
            # Add home-manager config
            {
              home-manager.users.pinpox = nixos-home.nixosModules.server;
            }

            # Modules
            ./modules/mmonit.nix
            ./modules/monit/default.nix
            ./modules/environment.nix
            ./modules/locale.nix
            ./modules/openssh.nix
            ./modules/zsh.nix

            # Other machine-specific configuration
            ./machines/porree/configuration.nix
          ];
        };
      };
    };
}
