inputs: flake-self:
let
  # Pass flake inputs to overlay so we can use the sources pinned in flake.lock
  # instead of having to keep sha256 hashes in each package for src
  inherit inputs;

  # Pass flake itself, so we can build woodpecker-pipeline and manual
  inherit flake-self;
in
self: super: {

  # TODO: fix infinite recursion
  # manual = super.callPackage ../packages/manual {
  #   inherit inputs;
  #   inherit flake-self;
  # };

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

  museum = super.callPackage ../packages/ente/museum.nix { };
  # ente-web = super.callPackage ../packages/ente/web.nix {};

  # TODO remove when fixed upsteam
  zynaddsubfx = super.zynaddsubfx.overrideAttrs (old: {
    CXXFLAGS = [
      # GCC 13: error: 'uint8_t' does not name a type
      "-include cstdint"
    ];
  });

  # Example package, used only for tests
  hello-custom = super.callPackage ../packages/hello-custom { };
  # river-luatile = super.callPackage ../packages/river-luatile { };
  fritzbox_exporter = super.callPackage ../packages/fritzbox_exporter { };
  mqtt2prometheus = super.callPackage ../packages/mqtt2prometheus { };

  # Custom packages. Will be made available on all machines and used where
  # needed.
  wezterm-bin = super.callPackage ../packages/wezterm-bin { };
  wezterm-nightly = super.callPackage ../packages/wezterm-nightly { };
  filebrowser = super.callPackage ../packages/filebrowser { };
  smartmon-script = super.callPackage ../packages/smartmon-script { };

  # Vim plugins, added inside existing pkgs.vimPlugins
  vimPlugins = super.vimPlugins // {
    indent-blankline-nvim-lua = super.callPackage ../packages/indent-blankline-nvim-lua {
      inputs = inputs;
    };
    zk-nvim = super.callPackage ../packages/zk-nvim { inputs = inputs; };
    nvim-fzf = super.callPackage ../packages/nvim-fzf { inputs = inputs; };
    nvim-cokeline = super.callPackage ../packages/nvim-cokeline { inputs = inputs; };
  };

  # ZSH plugins
  zsh-abbrev-alias = super.callPackage ../packages/zsh-abbrev-alias { inputs = inputs; };
  zsh-colored-man-pages = super.callPackage ../packages/zsh-colored-man-pages { inputs = inputs; };

  forgit = super.callPackage ../packages/forgit { inputs = inputs; };
  tfenv = super.callPackage ../packages/tfenv { inputs = inputs; };
}
