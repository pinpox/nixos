{
  description = "My machines";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # home-manager.url = "github:nix-community/home-manager";
    # nixos-home.url = "github:pinpox/nixos-home";
  };

  # outputs = { self, home-manager, nixpkgs }: {
  outputs = { self, nixpkgs }: {

    nixosConfigurations = {

      ahorn = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/ahorn/configuration.nix
          ./modules/lvm-grub.nix
        ];
      };

      birne = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [

          # Machine specific config
          ./machines/birne/configuration.nix

          # Include the results of the hardware scan.
          ./machines/birne/hardware-configuration.nix

          # User profiles
          ./modules/user-profiles/pinpox.nix

          # Reusables
          ./modules/lvm-grub.nix
          ./modules/dyndns.nix
          ./modules/monit/default.nix
          ./modules/environment.nix
          ./modules/locale.nix
          ./modules/openssh.nix
          ./modules/zsh.nix
          # ./modules/zabbix-agent.nix
        ];
      };

      kartoffel = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/kartoffel/configuration.nix

          # Include the results of the hardware scan.
          ./machines/kartoffel/hardware-configuration.nix

          # User Profiles
          ./modules/user-profiles/pinpox.nix

          # Include reusables
          ./modules/lvm-grub.nix
          ./modules/bluetooth.nix
          ./modules/environment.nix
          ./modules/fonts.nix
          ./modules/locale.nix
          ./modules/networking.nix
          ./modules/openssh.nix
          ./modules/sound.nix
          ./modules/virtualization.nix
          ./modules/xserver.nix
          ./modules/yubikey.nix
          ./modules/zsh.nix
          ./modules/borg/home.nix
          # ./modules/zabbix-agent.nix
        ];
      };

      kfbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./machines/kfbox/configuration.nix ];
      };

      mega = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./machines/mega/configuration.nix ];
      };

      porree = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [

          # User Profiles
          ./modules/user-profiles/pinpox.nix

          # Include reusables
          ./modules/mmonit.nix
          ./modules/monit/default.nix
          ./modules/environment.nix
          ./modules/locale.nix
          ./modules/openssh.nix
          ./modules/zsh.nix
          # ./modules/zabbix-server.nix

          # Other machine-specific configuration
          ./machines/porree/configuration.nix
        ];
      };
    };
  };
}
