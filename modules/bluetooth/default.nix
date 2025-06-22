{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.bluetooth;
in
{

  options.pinpox.defaults.bluetooth = {
    enable = mkEnableOption "default bluetooth configuration";
  };

  config = mkIf cfg.enable {

    hardware.bluetooth = {
      enable = true;
      # config = "
      #   [General]
      #   Enable=Source,Sink,Media,Socket
      # ";
    };

    services.blueman.enable = true;
  };
}
