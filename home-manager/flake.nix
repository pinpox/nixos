{
  description = "User configurations for pinpox";

  inputs.nur.url = "github:nix-community/NUR";
  inputs.dotfiles-awesome.url = "github:pinpox/dotfiles-awesome";
  inputs.neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";

  outputs = { self, nixpkgs, dotfiles-awesome, nur, neovim-nightly }: {
    # outputs = { self, nixpkgs, dotfiles-awesome, nur }: {

    nixosModules = {

      # Desktop configuration, includes GUI
      desktop = {
        imports = [
          ./home.nix
          dotfiles-awesome.nixosModules.dotfiles
          { nixpkgs.overlays = [ nur.overlay neovim-nightly.overlay ]; }
        ];
      };

      # Serevr user configuration, only CLI
      server = {
        imports = [
          ./home-server.nix
          { nixpkgs.overlays = [ nur.overlay neovim-nightly.overlay ]; }
        ];
      };
    };
  };
}
