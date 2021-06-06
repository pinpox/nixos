{ config, pkgs, lib, ... }: {
  services = {

    grobi = {
      enable = true;
      # executeAfter = [ " " ];
      rules = [{
        name = "kartoffel";
        outputs_connected = [ "DVI-D-0" "DP-0" "DVI-D-1" ];
        configure_row = [
          "DVI-D-0"
          "DP-0"
          "DVI-D-1"
        ];
        atomic = true;
        execute_after = [''
          ${pkgs.xorg.xrandr}/bin/xrandr \
          --output DVI-D-0 --mode 1920x1200 --pos 3460x0 --rotate normal \
          --output DP-0 --primary --mode 2560x1440 --pos 900x0 --rotate normal \
          --output DVI-D-1 --mode 1440x900 --pos 0x0 --rotate right \
          --output DP-1 --off \
          --output HDMI-0 --off
        ''];
      }];
    };
  };
}
