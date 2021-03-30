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

      # Output all modules in ./modules to flake
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
              pinpox.services = {
                borg-server.enable = true;
                home-assistant.enable = true;
                lvm-grub.enable = true;
              };
            }
          ];
        };

        bob = defFlakeSystem {
          imports = base-modules-server ++ [

            # Machine specific config
            ./machines/bob/configuration.nix
            ./machines/bob/hardware-configuration.nix

            {
              pinpox.services = {
                binary-cache.enable = true;
                droneci.enable = true;
                droneci.runner-exec.enable = true;
                droneci.runner-docker.enable = true;
                monitoring-server.http-irc.enable = true;
              };
            }

            # TODO bepasty service is currently broken due to:
            # https://github.com/NixOS/nixpkgs/issues/116326
            # https://github.com/bepasty/bepasty-server/issues/258
            # ./modules/bepasty/default.nix

          ];
        };

        kfbox = defFlakeSystem {
          imports = base-modules-server ++ [
            ./machines/kfbox/configuration.nix

            { nix.autoOptimiseStore = true; }

            {
              pinpox.services = {
                go-karma-bot.enable = true;
                hedgedoc.enable = true;
                mattermost.enable = true;
                thelounge.enable = true;
              };
            }
          ];
        };

        # mega =
        #   defFlakeSystem { imports = [ ./machines/mega/configuration.nix ]; };

        porree = defFlakeSystem {
          imports = base-modules-server
            ++ [ ./machines/porree/configuration.nix ];
        };
      };
    };
}
