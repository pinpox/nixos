{ config, pkgs, lib, ... }:
let vars = import ./vars.nix;
in {

  home.packages = with pkgs; [ starship ];

  # Prompt configuration
  home.file = {
    "starship.toml" = {
      source = ./starship.toml;
      target = ".config/starship.toml";
    };
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    autocd = true;
    dotDir = ".config/zsh";

    sessionVariables = {
      RPS1 = ""; # Disable the right side prompt that "walters" theme introduces
      ZDOTDIR = "/home/pinpox/.config/zsh";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    initExtraBeforeCompInit = builtins.readFile ./zshrc;
    initExtra = builtins.readFile ./zshrc-extra;

    history = {
      expireDuplicatesFirst = true;
      ignoreSpace = false;
      save = 15000;
      share = true;
    };

    dirHashes = {
      # Allows addressing directorys by shortname, e.g. `cd ~notes`
      docs = "$HOME/Documents";
      notes = "$HOME/Notes";
    };

    shellAliases = {

      # Exa ls replacement
      ls = "${pkgs.exa}/bin/exa --group-directories-first";
      l = "${pkgs.exa}/bin/exa -lbF --git --group-directories-first --icons";
      ll = "${pkgs.exa}/bin/exa -lbGF --git --group-directories-first --icons";
      llm =
        "${pkgs.exa}/bin/exa -lbGd --git --sort=modified --group-directories-first --icons";
      la =
        "${pkgs.exa}/bin/exa -lbhHigmuSa --time-style=long-iso --git --color-scale --group-directories-first --icons";
      lx =
        "${pkgs.exa}/bin/exa -lbhHigmuSa@ --time-style=long-iso --git --color-scale --group-directories-first --icons";
      lt =
        "${pkgs.exa}/bin/exa --tree --level=2 --group-directories-first --icons";

      # Pastebin (termbin.com)
      tb = "${pkgs.netcat-gnu}/bin/nc termbin.com 9999";
      tbc =
        "${pkgs.netcat-gnu}/bin/nc termbin.com 9999 | ${pkgs.xclip}/bin/xclip -selection c";

      # Gitignores
      git-ignore-create-go =
        "${pkgs.curl}/bin/curl 'https://www.toptal.com/developers/gitignore/api/vim,go,tags,ssh' > .gitignore";

      # Frequendly used folders
      cdn = "cd ~/code/github.com/pinpox/nixos";
      cdnh = "cd ~/code/github.com/pinpox/nixos-home";

      # Other
      lsblk = "lsblk -o name,mountpoint,label,size,type,uuid";
      c = "${pkgs.bat}/bin/bat -n --decorations never";
      cc =
        "${pkgs.clang}/bin/clang -Wall -Wextra -pedantic -std=c99 -Wshadow -Weverything";
      qr_gen = "${pkgs.qrencode}/bin/qrencode -t ansi -o-";
      top = "${pkgs.htop}/bin/htop";
      weather = "${pkgs.curl}/bin/curl -4 http://wttr.in/Koeln";
      radio = "${pkgs.mpv}/bin/mpv http://lassul.us:8000/radio.ogg";
      yotp = "${pkgs.yubikey-manager}/bin/ykman oath accounts code";
      zzz = "systemctl suspend";

      serve = "nix-shell -p python38Packages.httpcore --run 'python -m http.server 8080'"
    };

    prezto = {
      enable = true;

      # Case insensitive completion
      caseSensitive = false;

      # Autoconvert .... to ../..
      editor.dotExpansion = true;

      # Prezto modules to load
      # pmodules = [ "utility" "editor" "directory" "completion"];
      pmodules = [ "utility" "editor" "directory" ];

      terminal.autoTitle = true;
    };

    plugins = [
      {
        name = "fast-syntax-highlighting";
        file = "fast-syntax-highlighting.plugin.zsh";
        src = "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions";
      }
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = "${pkgs.zsh-nix-shell}/share/zsh-nix-shell";
      }
      {
        name = "zsh-abbrev-alias";
        file = "abbrev-alias.plugin.zsh";
        src = "${pkgs.zsh-abbrev-alias}/share/zsh-abbrev-alias";
      }
      {
        name = "zsh-colored-man-pages";
        file = "colored-man-pages.plugin.zsh";
        src = "${pkgs.zsh-colored-man-pages}/share/zsh-colored-man-pages";
      }
      {
        name = "zsh-fzf-tab";
        file = "fzf-tab.plugin.zsh";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];
  };

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

  programs.tmux = {
    enable = true;
    clock24 = true;
    prefix = "C-a";
    newSession = true;
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
