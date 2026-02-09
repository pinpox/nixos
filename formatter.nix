{
  treefmt-nix,
  nixpkgsFor,
  forAllSystems,
}:
forAllSystems (
  system:
  treefmt-nix.lib.evalModule nixpkgsFor.${system} {
    projectRootFile = "flake.nix";
    programs = {
      nixfmt.enable = true;
      nixfmt.package = nixpkgsFor.${system}.nixfmt;
      prettier.enable = true;
      shellcheck.enable = true;
      shfmt.enable = true;
    };
    settings.formatter = {
      prettier.includes = [
        "*.md"
        "*.yaml"
        "*.yml"
        "*.json"
        "*.toml"
      ];
      shellcheck.includes = [ "*.sh" ];
      shfmt.includes = [ "*.sh" ];
    };
  }
)
