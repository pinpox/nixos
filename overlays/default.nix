self: super: {
  # Custom packages. Will be made available on all machines and used where
  # needed.
  wezterm-bin = super.pkgs.callPackage ../packages/wezterm-bin { };
  wezterm-nightly = super.pkgs.callPackage ../packages/wezterm-nightly { };
  hello-custom = super.pkgs.callPackage ../packages/hello-custom { };
}
