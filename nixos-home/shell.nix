{ config, pkgs, lib, ... }: {

  # robbyrussell/oh-my-zsh folder:lib/completion

  # sindresorhus/pure
  # ael-code/zsh-colored-man-pages

  # momo-lab/zsh-abbrev-alias
  # zsh-users/zsh-completions
  # zsh-users/zsh-syntax-highlighting
  # mafredri/zsh-async
  # rupa/z

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    autocd = true;
    dotDir = ".config/zsh";
    sessionVariables = {
      RPS1 = ""; # Disable the right side prompt that "walters" theme introduces
      PURE_PROMPT_SYMBOL = "▸";
    };

    history = {
      expireDuplicatesFirst = true;
      ignoreSpace = false;
      save = 15000;
      share = true;
    };
    initExtra = ''
      abbrev-alias m="neomutt"
      abbrev-alias o="xdg-open"
      abbrev-alias q="exit"
      abbrev-alias snvim="sudo -E nvim"
      abbrev-alias v="nvim"

      # Global aliases, get expaned everywhere
      abbrev-alias -g G="| rg -i"
      abbrev-alias -g P="| tb"
    '';

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
      cdn = "cd ~/Projects/pinpox-nixos";
      cdnh = "cd ~/.config/nixpkgs";

      # Other
      lsblk = "lsblk -o name,mountpoint,label,size,type,uuid";
      c = "${pkgs.bat}/bin/bat -n --decorations never";
      cc =
        "${pkgs.clang}/bin/clang -Wall -Wextra -pedantic -std=c99 -Wshadow -Weverything";
      qr_gen = "${pkgs.qrencode}/bin/qrencode -t ansi -o-";
      top = "${pkgs.htop}/bin/htop";
      weather = "${pkgs.curl}/bin/curl -4 http://wttr.in/Koeln";
    };

    prezto = {
      enable = true;

      # Case insensitive completion
      caseSensitive = false;

      # Autoconvert .... to ../..
      editor.dotExpansion = true;

      # Prezto modules to load

      pmodules = [
        "utility"
        "completion"
        "environment"
        "terminal"
        "editor"
        "history"
        "directory"
        "syntax-highlighting"
        "history-substring-search"
      ];

    };

    plugins = [
      {
        name = "zsh-abbrev-alias";
        file = "abbrev-alias.plugin.zsh";
        src = builtins.fetchGit {
          url = "https://github.com/momo-lab/zsh-abbrev-alias";
        };
      }
      {
        name = "zsh-async";
        file = "async.zsh";
        src =
          builtins.fetchGit { url = "https://github.com/mafredri/zsh-async"; };
      }
      {
        name = "zsh-colored-man-pages";
        file = "colored-man-pages.plugin.zsh";
        src = builtins.fetchGit {
          url = "https://github.com/ael-code/zsh-colored-man-pages";
        };
      }
      {
        name = "zsh-syntax-highlighting";
        file = "zsh-syntax-highlighting.zsh";
        src = builtins.fetchGit {
          url = "https://github.com/zsh-users/zsh-syntax-highlighting/";
        };
      }
      # {
      #   name = "zsh-you-should-use";
      #   file = "you-should-use.plugin.zsh";
      #   src = builtins.fetchGit {
      #     url = "https://github.com/MichaelAquilina/zsh-you-should-use";
      #   };
      # }
      {
        name = "pure";
        # file = ".plugin.zsh";
        src =
          builtins.fetchGit { url = "https://github.com/sindresorhus/pure"; };
      }
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    # TODO more options
  };

  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
  };

  # TODO maybe replace with zoxide
  programs.pazi = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tmux = {
    enable = true;
    clock24 = true;
    # TODO other optoins

  };

  programs.htop = {
    enable = true;
    treeView = true;
  };

  programs.jq.enable = true;

  # Bat
  programs.bat = {
    enable = true;
    config = {
      # TODO look up opionts
      theme = "TwoDark";
    };
    # themes = { TODO };
  };

}
