{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.defaults.shell;
  colors = config.pinpox.colors;
in
{

  options.pinpox.defaults.shell = {
    enable = mkEnableOption "shell defaults";
    abbrev-aliases = mkOption {
      type =
        with types;
        listOf (submodule {
          options = {
            alias = mkOption { type = str; };
            command = mkOption { type = str; };
            global = mkOption {
              type = bool;
              default = false;
              description = "Expand alias everywhere, not only at the beginning of a line.";
            };
            recursive = mkOption {
              type = bool;
              default = false;
              description = "Expand aliases recursively";
            };
            eval = mkOption {
              type = bool;
              default = false;
              description = "Evaluate subshells on expansion";
            };
          };
        });

      example = [
        {
          alias = "nfu";
          command = "nix flake update --commit-lock-file";
        }
        {
          global = true;
          alias = "G";
          command = "| rg -i";
        }
      ];

      description = ''
        Aliases for abbrev-allias ZSH plugin
        https://github.com/momo-lab/zsh-abbrev-alias
      '';
    };
  };

  imports = [
    ./starship.nix
    ./zsh.nix
    # ./fish.nix
  ];

  config = mkIf cfg.enable {

    pinpox.defaults.shell.abbrev-aliases = [

      # Aliases expanded only at beginning of lines
      {
        alias = "g";
        command = "git";
      }
      {
        alias = "m";
        command = "neomutt";
      }
      {
        alias = "o";
        command = "xdg-open";
      }
      {
        alias = "q";
        command = "exit";
      }
      {
        alias = "snvim";
        command = "sudo -E nvim";
      }
      {
        alias = "v";
        command = "nvim";
      }
      {
        alias = "nfu";
        command = "nix flake update --commit-lock-file";
      }

      # Global aliases, get expanded everywhere
      {
        global = true;
        alias = "G";
        command = "| rg -i";
      }
      {
        global = true;
        alias = "P";
        command = "| tb";
      }
    ];

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
      # TODO: This should pick up the correct colors for the generated theme. Otherwise
      # it is possible to generate a custom bat theme to ~/.config/bat/config
      config = {
        theme = "base16";
      };
    };
  };
}
