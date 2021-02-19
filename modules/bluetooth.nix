{ config, pkgs, lib, ... }: {

  hardware.bluetooth = {
    enable = true;
    # config = "
    #   [General]
    #   Enable=Source,Sink,Media,Socket
    # ";
  };


            # Workaround until this hits unstable:
            # https://github.com/NixOS/nixpkgs/issues/113628
              systemd.services.bluetooth.serviceConfig.ExecStart = [
                ""
                "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf"
              ];


  services.blueman.enable = true;
}
