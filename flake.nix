{
  description = "My machines";

  outputs = { self, nixpkgs }: {

    # packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    # defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
    nixosConfigurations = {

      kartoffel = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./machines/kartoffel/configuration.nix
          ./machines/kartoffel/hardware-configuration.nix
        ];
      };

    };
  };
}
