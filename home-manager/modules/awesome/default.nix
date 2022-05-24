{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.awesome;
in
{
  options.pinpox.programs.awesome.enable = mkEnableOption "awesome window manager";

  config = mkIf cfg.enable {

    # imports = [ dotfiles-awesome.dotfiles ];

    xsession.scriptPath = ".hm-xsession";
    xsession.enable = true;

    xsession.windowManager.awesome = {
      enable = true;
      package = pkgs.awesome;

      # List of lua packages available for being used in the Awesome
      # configuration.
      luaModules = [ pkgs.luaPackages.lgi pkgs.luaPackages.luafilesystem ];

      # Disable client transparency support, which can be greatly detrimental to
      # performance in some setups
      # noArgd = true;
    };
  };
}
