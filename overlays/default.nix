inputs:
let
  # Pass flake inputs to overlay so we can use the sources pinned in flake.lock
  # instead of having to keep sha256 hashes in each package for src
  inherit inputs;
in self: super: {
  # Example package, used only for tests
  hello-custom = super.callPackage ../packages/hello-custom { };
  darktile = super.callPackage ../packages/darktile { };

  # Custom packages. Will be made available on all machines and used where
  # needed.
  wezterm-bin = super.callPackage ../packages/wezterm-bin { };
  wezterm-nightly = super.callPackage ../packages/wezterm-nightly { };
  filebrowser = super.callPackage ../packages/filebrowser { };
  zk = super.callPackage ../packages/zk { };

  # Vim plugins, added inside existing pkgs.vimPlugins
  vimPlugins = super.vimPlugins // {
    indent-blankline-nvim-lua =
      super.callPackage ../packages/indent-blankline-nvim-lua {
        inputs = inputs;
      };
    zk-nvim = super.callPackage ../packages/zk-nvim { inputs = inputs; };
    nvim-fzf = super.callPackage ../packages/nvim-fzf { inputs = inputs; };
    fzf-lua = super.callPackage ../packages/fzf-lua { inputs = inputs; };
  };



  # ZSH plugins
  zsh-abbrev-alias =
    super.callPackage ../packages/zsh-abbrev-alias { inputs = inputs; };
  zsh-colored-man-pages =
    super.callPackage ../packages/zsh-colored-man-pages { inputs = inputs; };

  forgit =
    super.callPackage ../packages/forgit { inputs = inputs; };
}

