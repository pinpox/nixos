{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.wayland;
in
{

  options.pinpox.services.wayland = {
    enable = mkEnableOption "wayland configuration";
  };

  config = mkIf cfg.enable {

    # Wayland/sway
    programs.sway.enable = true;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
      ];
    };

    # Turn on wayland support for some electron apps
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
      NIXOS_OZONE_WL = "1";
    };


    # Extra portals (screensharing)
    xdg.portal = {
      enable = true;
      config.common.default = [ "wlr" "gtk" ]; 
      wlr = {
        enable = true;
        settings = {
          screencast = {
            max_fps = 30;
            chooser_type = "simple";
            chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
          };
        };
      };
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    environment.systemPackages = [
      pkgs.xdg-desktop-portal
    ];

  };
}
