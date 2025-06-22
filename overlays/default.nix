inputs: flake-self: pinpox-utils:
let
  # Pass flake inputs to overlay so we can use the sources pinned in flake.lock
  # instead of having to keep sha256 hashes in each package for src
  inherit inputs;

  # Pass flake itself, so we can build woodpecker-pipeline and manual
  inherit flake-self;
in
self: super: {

  manual = super.callPackage ../packages/manual {
    inherit inputs;
    inherit pinpox-utils;
    inherit flake-self;
  };

  woodpecker-pipeline = super.callPackage ../packages/woodpecker-pipeline {
    inherit inputs;
    inherit flake-self;
  };

  # Override unfree src with flake input
  # ndi = super.ndi.overrideAttrs (old: {
  #   src = inputs.ndi-linux;
  #   unpackPhase = ''
  #     echo y | $src;
  #     sourceRoot="NDI SDK for Linux";
  #   '';
  # });

  # museum = super.callPackage ../packages/ente/museum.nix { };
  ente-web = super.callPackage ../packages/ente/web.nix { };

  # TODO remove when fixed upsteam
  zynaddsubfx = super.zynaddsubfx.overrideAttrs (old: {
    CXXFLAGS = [
      # GCC 13: error: 'uint8_t' does not name a type
      "-include cstdint"
    ];
  });

  # To override packages from master input do:
  # dmraid = inputs.nixpkgs-master.legacyPackages."${super.system}".dmraid;

  # Example package, used only for tests
  hello-custom = super.callPackage ../packages/hello-custom { };
  # river-luatile = super.callPackage ../packages/river-luatile { };
  fritzbox_exporter = super.callPackage ../packages/fritzbox_exporter { };
  mqtt2prometheus = super.callPackage ../packages/mqtt2prometheus { };

  # Custom packages. Will be made available on all machines and used where
  # needed.
  smartmon-script = super.callPackage ../packages/smartmon-script { };

  # Use custom neovim in standalone flake
  neovim = inputs.pinpox-neovim.packages.x86_64-linux.pinpox-neovim;

  # ZSH plugins
  zsh-abbrev-alias = super.callPackage ../packages/zsh-abbrev-alias { inputs = inputs; };
  zsh-colored-man-pages = super.callPackage ../packages/zsh-colored-man-pages { inputs = inputs; };

  forgit = super.callPackage ../packages/forgit { inputs = inputs; };
}
