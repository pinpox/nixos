{ config, pkgs, lib, ... }:
with lib;
let cfg = config.pinpox.defaults.zsh;
in
{

  options.pinpox.defaults.zsh = { enable = mkEnableOption "ZSH defaults"; };
  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [ zsh ];

    # Needed for yubikey to work
    environment.shellInit = ''
      export ZDOTDIR=$HOME/.config/zsh
    '';

    programs.zsh = {
      enable = true;
      shellAliases = { vim = "nvim"; };
      enableCompletion = true;
      autosuggestions.enable = true;
    };

    # Needed for zsh completion of system packages, e.g. systemd
    environment.pathsToLink = [ "/share/zsh" ];
  };
}
