{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.defaults.fonts;
in
{

  options.pinpox = {

    defaults.fonts.enable = mkEnableOption "font defaults";

    font = {
      normal = {
        family = mkOption {
          type = types.str;
          default = "Berkeley Mono";
        };
        style = mkOption {
          type = types.str;
          default = "Regular";
        };
      };
      bold = {
        family = mkOption {
          type = types.str;
          default = "Berkeley Mono";
        };
        style = mkOption {
          type = types.str;
          default = "Bold";
        };
      };
      italic = {
        family = mkOption {
          type = types.str;
          default = "Berkeley Mono";
        };
        style = mkOption {
          type = types.str;
          default = "Regular Italic";
        };
      };
      size = 10;
    };
  };

  config = mkIf cfg.enable {

    fonts.fontconfig.enable = true;
    # home.packages =
    #   [ flake-inputs.nix-apple-fonts.packages."x86_64-linux".sf-mono ];
  };
}
