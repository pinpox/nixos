{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.games;
in
{
  options.pinpox.programs.games.enable = mkEnableOption "games";
  config = mkIf cfg.enable {
    home.packages = with pkgs; [ retroarch-free ];
  };
}
