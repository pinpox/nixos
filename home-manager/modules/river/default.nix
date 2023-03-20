{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.river;
in
{
  options.pinpox.programs.river.enable = mkEnableOption "river window manager";

  config = mkIf cfg.enable {

    # Install these packages for my user
    home.packages = with pkgs; [ river ];

    xdg = {
      enable = true;
      configFile = {


        river-config = {
          target = "river/init_exta";
          text = ''
              riverctl map normal Super p spawn "${pkgs.wofi}/bin/wofi --show run"
              ${pkgs.waybar}/bin/waybar
              # ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 1920x1080 --pos 0,0 \
            # --output DP-1 --mode 2560x1440 --pos 4480,0 \
            # --output DP-2 --mode 2560x1440@164.54 --pos 1920,0
          '';
          executable = true;
        };
      };
    };




  };
}
