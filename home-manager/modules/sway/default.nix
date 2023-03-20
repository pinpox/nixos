{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.sway;
in
{
  options.pinpox.programs.sway.enable = mkEnableOption "sway window manager";

  config = mkIf cfg.enable {


    wayland.windowManager.sway = {
      enable = true;
      config = rec {
        modifier = "Mod4";
        # Use kitty as default terminal
        terminal = "${pkgs.lxterminal}/bin/lxterminal";
        startup = [
          # Launch Firefox on start
          # { command = "firefox"; }
        ];
        input = {
          "*" = {
            xkb_layout = "us";
            xkb_variant = "colemak";
          };
        };

        # output = {
        ##Phillips
        #DP-1 = {
        #  mode = "2560x1440@60";
        #};
        ## NZXT
        #DP-2 = {
        #  mode = "2560x1440@60";
        #};
        #};
      };
    };


  };
}
