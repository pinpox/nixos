{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.rio;
in
{
  options.pinpox.programs.rio.enable = mkEnableOption "rio terminal emulator";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ rio ];
    xdg.enable = true;
    xdg.configFile.rio.source = ./config/rio;
  };
}
