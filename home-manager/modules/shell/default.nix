{ colorscheme, config, lib, ... }:
with lib;
let
  cfg = config.pinpox.defaults.shell;

in
{

  options.pinpox.defaults.shell = { enable = mkEnableOption "shell defaults"; };


  imports = [ ./starship.nix ./zsh.nix ];
  config = mkIf cfg.enable {


    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultOptions = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--inline-info"
        "--color 'fg:#${colorscheme.White}'" # Text
        "--color 'bg:#${colorscheme.Black}'" # Background
        "--color 'preview-fg:#${colorscheme.White}'" # Preview window text
        "--color 'preview-bg:#${colorscheme.Black}'" # Preview window background
        "--color 'hl:#${colorscheme.Yellow}'" # Highlighted substrings
        "--color 'fg+:#${colorscheme.Blue}'" # Text (current line)
        "--color 'bg+:#${colorscheme.Grey}'" # Background (current line)
        "--color 'gutter:#${colorscheme.Grey}'" # Gutter on the left (defaults to bg+)
        "--color 'hl+:#${colorscheme.Magenta}'" # Highlighted substrings (current line)
        "--color 'info:#${colorscheme.Magenta}'" # Info line (match counters)
        "--color 'border:#${colorscheme.Blue}'" # Border around the window (--border and --preview)
        "--color 'prompt:#${colorscheme.White}'" # Prompt
        "--color 'pointer:#${colorscheme.Magenta}'" # Pointer to the current line
        "--color 'marker:#${colorscheme.Magenta}'" # Multi-select marker
        "--color 'spinner:#${colorscheme.Magenta}'" # Streaming input indicator
        "--color 'header:#${colorscheme.White}'" # Header
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
