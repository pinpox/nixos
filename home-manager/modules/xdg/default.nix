{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.defaults.xdg;
in
{

  options.pinpox.defaults.xdg = { enable = mkEnableOption "xdg defaults"; };

  config = mkIf cfg.enable {
    xdg = {
      enable = true;
      configFile = { };
    };
  };
}
