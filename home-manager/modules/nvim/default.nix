{
  config,
  pkgs,
  lib,
  utils,
  ...
}:

with lib;

let
  cfg = config.pinpox.programs.nvim;
in
{
  options.pinpox.programs.nvim.enable = mkEnableOption "neovim";

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ neovim ];

    xdg = {
      enable = true;
      configFile.nixcolors-lua = {
        target = "nvim/lua/nixcolors.lua";
        source = utils.renderMustache "nixcolors.lua" ./nixcolors.lua.mustache config.pinpox.colors;
      };
    };

    # Set env vars
    # TODO: which ones are really nedded?
    programs.zsh.sessionVariables.EDITOR = "nvim";
    programs.zsh.sessionVariables.VISUAL = "nvim";
    systemd.user.sessionVariables.EDITOR = "nvim";
    systemd.user.sessionVariables.VISUAL = "nvim";
    home.sessionVariables.EDITOR = "nvim";
    home.sessionVariables.VISUAL = "nvim";

  };
}
