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

    # Turn on wayland support for some electron apps
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    # Extra portals (screensharing)
    xdg.portal = {
      enable = true;
      config.common.default = [
        "wlr"
        "gtk"
      ];
      wlr = {
        enable = true;
        # xdph 0.8 negotiates WINDOW+MONITOR capture, which makes the built-in
        # "default" chooser skip slurp (chooser.c: type_mask != MONITOR) and
        # fall through to wofi/rofi/bemenu/... none of which are installed ->
        # "no output found". Forcing the simple chooser runs slurp unconditionally.
        settings.screencast = {
          chooser_type = "simple";
          chooser_cmd = "${pkgs.slurp}/bin/slurp -f 'Monitor: %o' -or";
        };
      };
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    environment.systemPackages = with pkgs; [
      xdg-desktop-portal
      wdisplays # Configure screen placement
    ];
  };
}
