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
      config = rec{
        keybindings =

          lib.mkOptionDefault
            {
              "${modifier}+Return" = "exec ${pkgs.foot}/bin/foot";
              "${modifier}+p" = "exec ${pkgs.wofi}/bin/wofi --show run";
            };

        # modifier = "Mod4"; # Windows key
        modifier = "Mod1"; # Alt key
        terminal = "${pkgs.foot}/bin/foot";
        # startup = [
        # Launch Firefox on start
        # { command = "firefox"; }
        # ];
        input = {
          "*" = {
            xkb_layout = "us";
            xkb_variant = "colemak";
          };
        };

        colors = { };
        # bars = { };
        fonts = {
          names = [ "Berkeley Mono" ];
          # style = "Bold Semi-Condensed";
          size = 11.0;

        };

        workspaceAutoBackAndForth = true;

        gaps = {
          bottom = 3;
          top = 3;
          horizontal = 3;
          vertical = 3;
          inner = 3;
          left = 3;
          right = 3;
          outer = 3;
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
