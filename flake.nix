{
  description = "My machines";

  outputs = { self, nixpkgs }: {

    # packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    # defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
    nixosConfigurations = {

      ahorn = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/ahorn/configuration.nix
          ./machines/ahorn/hardware-configuration.nix
        ];
      };

      birne = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/birne/configuration.nix
          ./machines/birne/hardware-configuration.nix
        ];
      };

      kartoffel = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/kartoffel/configuration.nix
          ./machines/kartoffel/hardware-configuration.nix
        ];
      };

      kfbox = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/kfbox/configuration.nix
          ./machines/kfbox/hardware-configuration.nix
        ];
      };

      mega = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/mega/configuration.nix
          ./machines/mega/hardware-configuration.nix
        ];
      };

      porree = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./machines/porree/configuration.nix ];
      };

    };
  };
}
