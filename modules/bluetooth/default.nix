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

    # Workaround until this hits unstable:
    # TODO https://github.com/NixOS/nixpkgs/issues/113628
    systemd.services.bluetooth.serviceConfig.ExecStart = [
      ""
      "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf"
    ];

    services.blueman.enable = true;
  };
}
