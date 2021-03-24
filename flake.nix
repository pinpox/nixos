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
        ./modules/environment
        ./modules/locale
        ./modules/wireguard-client.nix
        ./modules/monitoring
        ./modules/nix-common
        {
          # pinpox.metrics.node.enable = true;
          pinpox.defaults = {
            environment.enable = true;
            locale.enable = true;
            nix.enable = true;
          };
        }
        ./modules/zsh.nix
        ./modules/openssh.nix
        ./modules/networking.nix
      ];

    in {

      nixosConfigurations = {

        # inherit nixpkgs nixpkgs-pinned;

        kartoffel = defFlakeSystem {
          imports = [
            ./modules/base/desktop.nix
            ./machines/kartoffel/hardware-configuration.nix
            {

              # Video driver for nvidia graphics card
              services.xserver.videoDrivers = [ "nvidia" ];
              boot.blacklistedKernelModules = [ "nouveau" ];

              # To build raspi images
              boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

              pinpox.desktop = {
                enable = true;
                wireguardIp = "192.168.7.3";
                hostname = "kartoffel";
                homeConfig = nixos-home.nixosModules.desktop;
                bootDevice =
                  "/dev/disk/by-uuid/608e0e77-eea4-4dc4-b88d-76cc63e4488b";
              };
            }
          ];
        };

        ahorn = defFlakeSystem {
          imports = [
            ./modules/base/desktop.nix
            ./machines/ahorn/hardware-configuration.nix
            {

              boot.blacklistedKernelModules = [ "nouveau" ];

              pinpox.desktop = {
                enable = true;
                wireguardIp = "192.168.7.2";
                hostname = "ahorn";
                homeConfig = nixos-home.nixosModules.desktop;
                bootDevice =
                  "/dev/disk/by-uuid/d4b70087-c965-40e8-9fca-fc3b2606a590";
              };
            }
          ];
        };

        birne = defFlakeSystem {
          imports = base-modules-server ++ [

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
            # ./modules/monitoring/telegraf.nix

          ];
        };

        bob = defFlakeSystem {
          imports = base-modules-server ++ [

            # Machine specific config
            ./machines/bob/configuration.nix
            ./machines/bob/hardware-configuration.nix

            # Modules
            # ./modules/wireguard-client.nix

            # TODO the drone-docker-exec module has no enable options yet and
            # will therefore always be setup when the droneci/default.nix is
            # imported
            ./modules/drone-ci
            ./modules/binary-cache
            {
              pinpox.services.binary-cache.enable = true;

              # TODO the drone-docker-exec module has no enable options yet and
              # will therefore always be setup when the droneci/default.nix is
              # imported
              pinpox.services.droneci.enable = true;
            }

            # TODO bepasty service is currently broken due to:
            # https://github.com/NixOS/nixpkgs/issues/116326
            # https://github.com/bepasty/bepasty-server/issues/258
            # ./modules/bepasty/default.nix

            # ./modules/lvm-grub.nix
            # ./modules/monitoring/telegraf.nix
          ];
        };

        kfbox = defFlakeSystem {
          imports = base-modules-server ++ [
            ./machines/kfbox/configuration.nix

            { nix.autoOptimiseStore = true; }

            ./modules/irc-bot
            {
              pinpox.services.go-karma-bot.enable = true;
            }

            # ./modules/monitoring/telegraf.nix
            # ./modules/wireguard-client.nix
            ./modules/mattermost/default.nix
            ./modules/thelounge.nix
            ./modules/hedgedoc.nix
          ];
        };

        # mega =
        #   defFlakeSystem { imports = [ ./machines/mega/configuration.nix ]; };

        porree = defFlakeSystem {
          imports = base-modules-server ++ [
            ./machines/porree/configuration.nix

            # ./modules/drone-ci/default.nix
            ./modules/monitoring/prometheus.nix
            ./modules/monitoring/loki.nix
            ./modules/monitoring/grafana.nix
            ./modules/monitoring/alertmanager-irc-relay.nix
            ./modules/wireguard-client.nix
            # ./modules/monitoring/telegraf.nix
          ];
        };
      };
    };
}
