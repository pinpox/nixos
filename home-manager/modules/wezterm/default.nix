{
  lib,
  pkgs,
  config,
  pinpox-utils,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.wezterm;
in
{
  options.pinpox.programs.wezterm.enable = mkEnableOption "wezterm terminal emulator";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [

      wezterm
      # (callPackage ../../../packages/wezterm-nightly { })
    ];
    # [ (callPackage ../../../packages/wezterm-bin { }) ];

    xdg = {
      enable = true;
      configFile = {

        colors_lua = {
          target = "wezterm/colors.lua";
          source = pinpox-utils.renderMustache "colors.lua" ./colors.lua.mustache config.pinpox.colors;
        };

        wezterm_lua = {
          target = "wezterm/wezterm.lua";
          source = ./wezterm.lua;
        };
      };
    };
  };
}
