{ config, pkgs, lib, ... }: {

  hardware.bluetooth = {
    enable = true;
    # config = "
    #   [General]
    #   Enable=Source,Sink,Media,Socket
    # ";
  };

  services.blueman.enable = true;
}
