inputs:
let
  # Pass flake inputs to overlay so we can use the sources pinned in flake.lock
  # instead of having to keep sha256 hashes in each package for src
  inherit inputs;
in self: super: {

  # Example package, used only for tests
  hello-custom = super.pkgs.callPackage ../packages/hello-custom { };

  # Custom packages. Will be made available on all machines and used where
  # needed.
  wezterm-bin = super.pkgs.callPackage ../packages/wezterm-bin { };
  wezterm-nightly = super.pkgs.callPackage ../packages/wezterm-nightly { };
  filebrowser = super.pkgs.callPackage ../packages/filebrowser { };

  # Vim plugins, added inside existing pkgs.vimPlugins
  vimPlugins = super.vimPlugins // {
    indent-blankline-nvim-lua =
      super.pkgs.callPackage ../packages/indent-blankline-nvim-lua {
        inputs = inputs;
      };
  };

  # ZSH plugins
  zsh-abbrev-alias =
    super.pkgs.callPackage ../packages/zsh-abbrev-alias { inputs = inputs; };
  zsh-colored-man-pages =
    super.pkgs.callPackage ../packages/zsh-colored-man-pages {
      inputs = inputs;
    };
}
