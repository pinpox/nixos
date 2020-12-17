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
          ./common/user-profiles/pinpox.nix

          # Include reusables
          ./common/bluetooth.nix
          ./common/environment.nix
          ./common/fonts.nix
          ./common/locale.nix
          ./common/networking.nix
          ./common/openssh.nix
          ./common/sound.nix
          ./common/virtualization.nix
          ./common/xserver.nix
          ./common/yubikey.nix
          ./common/zsh.nix
          #../../common/borg/home.nix
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
        modules = [ ./machines/porree/configuration.nix ];
      };

    };
  };
}
