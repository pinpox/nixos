{
  description = "My machines";

  inputs = { nixpkgs = { url = "github:nixos/nixpkgs/nixos-unstable"; }; };

  outputs = { self, nixpkgs }: {

    nixosConfigurations = {

      ahorn = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./machines/ahorn/configuration.nix ];
      };

      birne = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./machines/birne/configuration.nix ];
      };

      kartoffel = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/kartoffel/configuration.nix

          # Include the results of the hardware scan.
          ./machines/kartoffel/hardware-configuration.nix

          # User Profiles
          ./modules/user-profiles/pinpox.nix

          ./modules/custom-packages.nix

          # Include reusables
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
          #../../modules/borg/home.nix
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
          ./machines/porree/configuration.nix

          # User Profiles
          ./modules/user-profiles/pinpox.nix

          # Include reusables
          ./modules/environment.nix
          ./modules/locale.nix
          ./modules/openssh.nix
          ./modules/zsh.nix
        ];
      };

    };
  };
}
