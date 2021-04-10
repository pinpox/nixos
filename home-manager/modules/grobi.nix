{ config, pkgs, lib, ... }: {
  services = {

    # grobi = {
    #   enable = true;
    #   # executeAfter = [ " " ];
    #   rules = [{
    #     name = "Kartoffel";
    #     outputs_connected = [ "DVI-D-0" "DVI-D-1" "HDMI-0" ];
    #     configure_row = [ "DVI-D-0" "HDMI-0" "DVI-D-1" ];
    #     primary = "HDMI-0";
    #     atomic = true;
    #     execute_after = [
    #   "${pkgs.xorg.xrandr}/bin/xrandr --output DVI-D-0 --mode 1440x900 --pos 0x0 --rotate right --output HDMI-0 --primary --mode 1920x1200 --pos 900x0 --rotate normal --output DP-0 --off --output DP-1 --off --output DVI-D-1 --mode 1280x1024 --pos 2820x0 --rotate normal"
    #       # "${pkgs.xmonad-with-packages}/bin/xmonad --restart";
    #     ];
    #   }];
    # };
  };
}
