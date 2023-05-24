{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.defaults.shell;
  colors = config.pinpox.colors;
in
{

  options.pinpox.defaults.shell = { enable = mkEnableOption "shell defaults"; };

  imports = [
    ./starship.nix
    ./zsh.nix
    # ./fish.nix
  ];

  config = mkIf cfg.enable {

    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
        "--color 'fg:#${colors.White}'" # Text
        "--color 'bg:#${colors.Black}'" # Background
        "--color 'preview-fg:#${colors.White}'" # Preview window text
        "--color 'preview-bg:#${colors.Black}'" # Preview window background
        "--color 'hl:#${colors.Yellow}'" # Highlighted substrings
        "--color 'fg+:#${colors.Blue}'" # Text (current line)
        "--color 'bg+:#${colors.BrightBlack}'" # Background (current line)
        "--color 'gutter:#${colors.BrightBlack}'" # Gutter on the left (defaults to bg+)
        "--color 'hl+:#${colors.Magenta}'" # Highlighted substrings (current line)
        "--color 'info:#${colors.Magenta}'" # Info line (match counters)
        "--color 'border:#${colors.Blue}'" # Border around the window (--border and --preview)
        "--color 'prompt:#${colors.White}'" # Prompt
        "--color 'pointer:#${colors.Magenta}'" # Pointer to the current line
        "--color 'marker:#${colors.Magenta}'" # Multi-select marker
        "--color 'spinner:#${colors.Magenta}'" # Streaming input indicator
        "--color 'header:#${colors.White}'" # Header
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
  };
}
