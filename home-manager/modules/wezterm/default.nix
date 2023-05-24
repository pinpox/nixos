{ lib, pkgs, config, utils, ... }:
with lib;
let
  cfg = config.pinpox.programs.wezterm;
in
{
  options.pinpox.programs.wezterm.enable =
    mkEnableOption "wezterm terminal emulator";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      inconsolata-nerdfont # Fallback Nerd Font to provide special glyphs
      wezterm
      # (callPackage ../../../packages/wezterm-nightly { })
    ];
    # [ (callPackage ../../../packages/wezterm-bin { }) ];

    xdg = {
      enable = true;
      configFile = {

        colors_lua = {
          target = "wezterm/colors.lua";
          source =
            utils.renderMustache "colors.lua" ./colors.lua.mustache config.pinpox.colors;
        };

        wezterm_lua = {
          target = "wezterm/wezterm.lua";
          source = ./wezterm.lua;
        };
      };
    };
  };
}
