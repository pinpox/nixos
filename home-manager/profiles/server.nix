{ config, pkgs, lib, ... }:
let
  splitString = str:
    builtins.filter builtins.isString (builtins.split "\n" str);
in
{

  # Allow "unfree" licenced packages
  nixpkgs.config = { allowUnfree = true; };

  # Install these packages for my user
  home.packages = with pkgs; [ exa htop httpie pkg-config tealdeer unzip ];

  # Imports
  imports = [
    ../modules/credentials.nix
    ../modules/git.nix
    ../modules/shell
    ../modules/vim
    ../modules/xdg.nix
  ];

  # _module.args.utils = import ../utils { inherit pkgs; };

  # Include man-pages
  manual.manpages.enable = true;

  # Environment variables
  systemd.user.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    # ZDOTDIR = "$XDG_CONFIG_HOME/zsh";
  };

  home.sessionVariables = {
    # Workaround for alacritty
    EDITOR = "nvim";
    VISUAL = "nvim";
    ZDOTDIR = "/home/pinpox/.config/zsh";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # programs.neovim.package = pkgs.neovim-nightly;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";
}
