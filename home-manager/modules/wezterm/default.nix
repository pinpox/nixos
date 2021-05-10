{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.programs.wezterm;
in {
  options.pinpox.programs.wezterm.enable =
    mkEnableOption "wezterm terminal emulator";

  config = mkIf cfg.enable {
    home.packages = with pkgs;
    [
      inconsolata-nerdfont # Fallback Nerd Font to provide special glyphs
      (callPackage ../../../packages/wezterm-nightly { }) ];
      # [ (callPackage ../../../packages/wezterm-bin { }) ];

    xdg = {
      enable = true;
      configFile = {
        wezterm_lua = {
          target = "wezterm/wezterm.lua";
          source = ./wezterm.lua;
        };
      };
    };
  };
}
