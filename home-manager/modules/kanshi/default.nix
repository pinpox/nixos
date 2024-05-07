{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.kanshi;
in
{
  options.pinpox.programs.kanshi.enable = mkEnableOption "kanshi screen setup";

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ kanshi ];

    # output eDP-1 mode 1920x1080 position 0,0
    #       output DP-1 mode 2560x1440 position 1080,0
    #       output DP-2 mode 2560x1440 position 3640,0

    services.kanshi = {
      enable = true;
      profiles = {

        laptop-only = {
          outputs = [
            {
              criteria = "eDP-1";
              mode = "1920x1080@60Hz";
            }
          ];
        };
        triple-home = {
          outputs = [

            # generate with wlay
            #output "eDP-1" {
            #mode 1920x1080@60Hz
            #pos 0 0
            #transform normal
            #}
            #output "DP-1" {
            #mode 2560x1440@59Hz
            #pos 4480 0
            #transform normal
            #}
            #output "DP-2" {
            #mode 2560x1440@59Hz
            #pos 1920 0
            #transform normal
            #}

            {
              criteria = "eDP-1";
              mode = "1920x1080@60Hz";
              position = "0,0";
              status = "enable";
            }
            {
              criteria = "DP-1";
              mode = "2560x1440@60Hz";
              position = "4480,0";
              status = "enable";
            }
            {
              criteria = "DP-2";
              mode = "2560x1440@60Hz";
              position = "1920,0";
              status = "enable";
            }
          ];
        };
      };
    };
  };
}
