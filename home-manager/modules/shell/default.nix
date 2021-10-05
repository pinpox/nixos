{ config, pkgs, lib, ... }:
let vars = import ../vars.nix;
in {

  imports = [
    ./starship.nix
    ./zsh.nix
  ];

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
      "--inline-info"
      "--color 'fg:#${vars.colors.White}'" # Text
      "--color 'bg:#${vars.colors.Black}'" # Background
      "--color 'preview-fg:#${vars.colors.White}'" # Preview window text
      "--color 'preview-bg:#${vars.colors.Black}'" # Preview window background
      "--color 'hl:#${vars.colors.Yellow}'" # Highlighted substrings
      "--color 'fg+:#${vars.colors.Blue}'" # Text (current line)
      "--color 'bg+:#${vars.colors.Grey}'" # Background (current line)
      "--color 'gutter:#${vars.colors.Grey}'" # Gutter on the left (defaults to bg+)
      "--color 'hl+:#${vars.colors.Magenta}'" # Highlighted substrings (current line)
      "--color 'info:#${vars.colors.Magenta}'" # Info line (match counters)
      "--color 'border:#${vars.colors.Blue}'" # Border around the window (--border and --preview)
      "--color 'prompt:#${vars.colors.White}'" # Prompt
      "--color 'pointer:#${vars.colors.Magenta}'" # Pointer to the current line
      "--color 'marker:#${vars.colors.Magenta}'" # Multi-select marker
      "--color 'spinner:#${vars.colors.Magenta}'" # Streaming input indicator
      "--color 'header:#${vars.colors.White}'" # Header
    ];
  };

  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.pazi = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.htop = {
    enable = true;
    settings.tree_view = true;
  };

  programs.jq.enable = true;

  programs.bat = {
    enable = true;
    # This should pick up the correct colors for the generated theme. Otherwise
    # it is possible to generate a custom bat theme to ~/.config/bat/config
    config = { theme = "base16"; };
  };
}
