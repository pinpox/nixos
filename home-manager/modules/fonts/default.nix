{ config, pkgs, lib, nur, utils, ... }:
with lib;
let
  vars = import ../vars.nix;
  cfg = config.pinpox.defaults.fonts;
in
{
  options.pinpox.defaults.fonts.enable = mkEnableOption "font defaults";

  config = mkIf cfg.enable {

    fonts.fontconfig.enable = true;
    # home.packages =
    #   [ flake-inputs.nix-apple-fonts.packages."x86_64-linux".sf-mono ];
  };
}
