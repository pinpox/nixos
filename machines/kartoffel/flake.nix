{
  description = "Kartoffel Desktop";

  outputs = { self, nixpkgs }: {

    # packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    # defaultPackage.x86_64-linux = self.packages.x86_64-linux.hello;
    nixosConfigurations.kartoffel = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ./hardware-configuration.nix

        ./common/user-profiles/pinpox.nix
        ./common/sound.nix
        ./common/openssh.nix
        ./common/environment.nix
        ./common/xserver.nix
        ./common/networking.nix
        ./common/bluetooth.nix
        ./common/fonts.nix
        ./common/locale.nix
        ./common/yubikey.nix
        ./common/virtualization.nix
        ./common/zsh.nix
        # Include reusables
        # <common/borg/home.nix>
      ];
    };

  };
}
