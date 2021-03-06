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
  outputs = { self, nixpkgs, nixpkgs-pinned, home-manager, nixos-home }:
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
                  # Set the $NIX_PATH entry for nixpkgs. This is necessary in
                  # this setup with flakes, otherwise commands like `nix-shell
                  # -p pkgs.htop` will keep using an old version of nixpkgs.
                  # With this entry in $NIX_PATH it is possible (and
                  # recommended) to remove the `nixos` channel for both users
                  # and root e.g. `nix-channel --remove nixos`. `nix-channel
                  # --list` should be empty for all users afterwards
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

        base-modules-server = [
            ./modules/user-profiles/pinpox.nix
            { home-manager.users.pinpox = nixos-home.nixosModules.server; }
            ./modules/borg/default.nix
            ./modules/environment.nix
            ./modules/zsh.nix
            ./modules/openssh.nix
            ./modules/networking.nix
            ./modules/locale.nix
            ./modules/nix-common.nix
        ];

        base-modules-desktop = [

            ./modules/user-profiles/pinpox.nix
            { home-manager.users.pinpox = nixos-home.nixosModules.desktop; }

            ./modules/bluetooth.nix
            ./modules/borg/default.nix
            ./modules/environment.nix
            ./modules/locale.nix
            ./modules/lvm-grub.nix
            ./modules/networking.nix
            ./modules/openssh.nix
            ./modules/sound.nix
            ./modules/virtualization.nix
            ./modules/xserver.nix
            ./modules/yubikey.nix
            ./modules/zsh.nix
            ./modules/nix-common.nix
            ./modules/wireguard-client.nix
        ];

    in {
        apps.deploy = pkgs.callPackage ./nixos/krops.nix {
      inherit (krops.packages.${system}) writeCommand;
      lib = krops.lib;
    };
      nixosConfigurations = {

        inherit nixpkgs nixpkgs-pinned;

        kartoffel = defFlakeSystem {
          imports = base-modules-desktop ++ [
            ./machines/kartoffel/configuration.nix
            ./machines/kartoffel/hardware-configuration.nix
          ];
        };

        ahorn = defFlakeSystem {
          imports = base-modules-desktop ++ [
            ./machines/ahorn/configuration.nix
            ./machines/ahorn/hardware-configuration.nix
          ];
        };

        birne = defFlakeSystem {
          imports = base-modules-server  ++ [

            # Machine specific config
            ./machines/birne/configuration.nix
            ./machines/birne/hardware-configuration.nix

            {
              nixpkgs.overlays = [
                (final: prev: {
                  nixpkgs-pinned = nixpkgs-pinned.legacyPackages.${prev.system};
                })
              ];
            }

            # Modules
            ./modules/borg-server.nix
            ./modules/lvm-grub.nix
            ./modules/home-assistant/default.nix
            ./modules/monitoring/telegraf.nix

          ];
        };


        bob = defFlakeSystem {
          imports = base-modules-server  ++ [

            # Machine specific config
            ./machines/bob/configuration.nix
            ./machines/bob/hardware-configuration.nix

            # Modules
            # ./modules/wireguard-client.nix
            ./modules/drone-ci/default.nix
            ./modules/drone-ci/drone-runner-docker.nix
            # ./modules/lvm-grub.nix
            # ./modules/monitoring/telegraf.nix
          ];
        };

        kfbox = defFlakeSystem {
          imports = base-modules-server ++ [
            ./machines/kfbox/configuration.nix

            { nix.autoOptimiseStore = true; }

            ./modules/monitoring/telegraf.nix
            ./modules/wireguard-client.nix
            ./modules/mattermost/default.nix
            ./modules/thelounge.nix
            ./modules/hedgedoc.nix
          ];
        };

        mega =
          defFlakeSystem { imports = [ ./machines/mega/configuration.nix ]; };


        porree = defFlakeSystem {
          imports = base-modules-server ++ [
            ./machines/porree/configuration.nix

            # ./modules/drone-ci/default.nix
            ./modules/monitoring/prometheus.nix
            ./modules/monitoring/loki.nix
            ./modules/monitoring/telegraf.nix
          ];
        };
      };
    };
}
