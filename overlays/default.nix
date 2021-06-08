self: super: {
  hello-custom = super.pkgs.callPackage ../packages/hello-custom { };
  hello-custom-test = super.pkgs.callPackage ../packages/hello-custom-test { };
  wezterm-bin = super.pkgs.callPackage ../packages/wezterm-bin { };
  wezterm-nightly = super.pkgs.callPackage ../packages/wezterm-nightly { };
}
