{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.river;
  start-river =
    pkgs.writeShellScriptBin "start-river" # sh
      ''
        export WLR_DRM_NO_MODIFIERS=1
        dbus-launch --sh-syntax --exit-with-session ${pkgs.river-classic}/bin/river
      '';

  screenshot-region =
    pkgs.writeShellScriptBin "screenshot-region" # sh
      ''
        ${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png
      '';

  screenshot-region-satty =
    pkgs.writeShellScriptBin "screenshot-region-satty" # sh
      ''
        ${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.satty}/bin/satty --filename - --early-exit --initial-tool brush --font-family ${config.pinpox.font.normal.family}
      '';

  screenshot-region-file =
    pkgs.writeShellScriptBin "screenshot-region-file" # sh
      ''
        ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" $(date +'%s_grim.png')
      '';
in
{
  options.pinpox.programs.river.enable = mkEnableOption "river window manager";

  config = mkIf cfg.enable {

    # Sets --indicator for network-manager-applet, which makes it work in river
    xsession.preferStatusNotifierItems = true;

    # Install these packages for my user
    home.packages = with pkgs; [
      river-classic
      river-luatile
      # way-displays
      waybar
      wl-clipboard
      wlr-randr
      start-river
      screenshot-region
      screenshot-region-satty
      screenshot-region-file
    ];

    xdg = {
      enable = true;
      configFile = {

        # River configuration files
        river-config = {
          target = "river/init";
          source = ./river-config;
          executable = true;
        };

        river-config-extra = {
          target = "river/init_exta";
          text = # sh
            ''
              riverctl map-switch normal lid close spawn ${pkgs.swaylock}/bin/swaylock
              # riverctl map normal Super F12 spawn '${pkgs.slurp}/bin/slurp | ${pkgs.grim}/bin/grim -g - - | ${pkgs.wl-clipboard}/bin/wl-copy -t image/png'
              # riverctl map normal Super F12 spawn ${screenshot-region}
              riverctl map normal Super p spawn "${pkgs.tofi}/bin/tofi-run"

              ${pkgs.mako}/bin/mako &
              waybar
              # ${pkgs.wlr-randr}/bin/wlr-randr --output eDP-1 --mode 1920x1080 --pos 0,0 \
              # --output DP-1 --mode 2560x1440 --pos 4480,0 \
              # --output DP-2 --mode 2560x1440@164.54 --pos 1920,0

              # wlr-randr --output eDP-1 --on --mode 1920x1080 --pos 0,0 --output DP-1  --on --mode 2560x1440 --pos 4480,0 --output DP-2  --on --mode 2560x1440  --pos 1920,0

            '';
          executable = true;
        };

        # river-luatile layouts
        luatile-layout = {
          target = "river-luatile/layout.lua";
          source = ./layout.lua;
        };

        luatile-json = {
          target = "river-luatile/json.lua";
          source = ./json.lua;
        };
      };
    };
  };
}
