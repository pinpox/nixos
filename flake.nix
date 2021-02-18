{
  description = "My machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # nixpkgs-pinned.url =
    #   "github:nixos/nixpkgs/c4d27d698a5925b94715ae8972d215e033023cd9";
    nixpkgs-pinned.url = "github:nixos/nixpkgs/nixos-unstable";

    # TODO workaround until prezto fix
    home-manager.url = "github:pinpox/home-manager/fix-prezto-runcom";
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
    in {
      nixosConfigurations = {

        inherit nixpkgs nixpkgs-pinned;

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
            {
              boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
            }

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
            ./machines/ahorn/hardware-configuration.nix

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
            { home-manager.users.pinpox = nixos-home.nixosModules.server; }

            {
              nixpkgs.overlays = [
                (final: prev: {
                  nixpkgs-pinned = nixpkgs-pinned.legacyPackages.${prev.system};
                })
              ];
            }

            # Modules
            ./modules/borg-server.nix
            ./modules/dyndns.nix
            ./modules/environment.nix
            ./modules/locale.nix
            ./modules/lvm-grub.nix
            # ./modules/monit/default.nix
            ./modules/home-assistant/default.nix
            # ./modules/zabbix-agent.nix
            ./modules/monitoring/telegraf.nix

            ./modules/openssh.nix
            ./modules/zsh.nix
            ./modules/borg-monitor-repo.nix
          ];
        };

        kfbox = defFlakeSystem {
          imports = [

            ./machines/kfbox/configuration.nix

            ./modules/user-profiles/pinpox.nix

            # Add home-manager config
            # { home-manager.users.pinpox = nixos-home.nixosModules.server; }

            ./modules/environment.nix
            ./modules/locale.nix
            ./modules/monitoring/telegraf.nix
            ./modules/nix-common.nix
            ./modules/openssh.nix
            ./modules/wireguard-client.nix

            ./modules/mattermost/default.nix
            ./modules/thelounge.nix
            ./modules/hedgedoc.nix
            # ./modules/zsh.nix

          ];
        };

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
            # ./modules/mmonit.nix
            # ./modules/monit/default.nix
            # ./modules/munin-master.nix
            # ./modules/zabbix-server.nix
            ./modules/networking.nix
            ./modules/environment.nix
            ./modules/locale.nix
            ./modules/openssh.nix
            ./modules/zsh.nix
            ./modules/monitoring/prometheus.nix
            ./modules/monitoring/loki.nix
            ./modules/monitoring/telegraf.nix

            # Other machine-specific configuration
            ./machines/porree/configuration.nix
          ];
        };
      };
    };
}
