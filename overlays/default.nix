self: super: {
  # Custom packages. Will be made available on all machines and used where
  # needed.
  wezterm-bin = super.pkgs.callPackage ../packages/wezterm-bin { };
  wezterm-nightly = super.pkgs.callPackage ../packages/wezterm-nightly { };

  hello-custom = super.pkgs.callPackage ../packages/hello-custom { };

  # Add plugins to vimPlugins that are not packaged yet
  vimPlugins = super.vimPlugins // {
    indent-blankline-nvim-lua2 =
      super.pkgs.callPackage ../packages/indent-blankline-nvim-lua { };
  };
}
