{ config, pkgs, lib, ... }: {

  environment.systemPackages = with pkgs; [
    zsh
  ];

  programs.zsh = {
    enable = true;
    shellAliases = { vim = "nvim"; };
    enableCompletion = true;
    autosuggestions.enable = true;
  };

  # Needed for zsh completion of system packages, e.g. systemd
  environment.pathsToLink = [ "/share/zsh" ];
}
