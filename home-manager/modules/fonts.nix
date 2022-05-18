{ config
, pkgs
, lib
, flake-inputs
, ...
}: {
  fonts.fontconfig.enable = true;
  # home.packages =
  #   [ flake-inputs.nix-apple-fonts.packages."x86_64-linux".sf-mono ];
}
