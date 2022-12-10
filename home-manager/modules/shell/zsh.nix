{ pkgs, promterm, ... }: {
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

    shellAliases = rec {

      # Exa ls replacement
      ls = "${pkgs.exa}/bin/exa --group-directories-first";
      l = "${ls} -lbF --git --icons";
      ll = "${l} -G";
      la =
        "${ls} -lbhHigmuSa@ --time-style=long-iso --git --color-scale --icons";
      lt = "${ls} --tree --level=2 --icons";

      # Git
      gs = "${pkgs.git}/bin/git status";

      # Pastebin (termbin.com)
      tb = "${pkgs.netcat-gnu}/bin/nc termbin.com 9999";
      tbc = "${tb} | ${pkgs.xclip}/bin/xclip -selection c";

      # Frequendly used folders
      cdn = "cd ~/code/github.com/pinpox/nixos";
      cdnh = "cd ~/code/github.com/pinpox/nixos-home";

      # Other
      pt = "${promterm.defaultPackage.x86_64-linux}/bin/promterm 'https://vpn.prometheus.pablo.tools/api/v1/alerts'";
      lsblk = "lsblk -o name,mountpoint,label,size,type,uuid";
      c = "${pkgs.bat}/bin/bat -n --decorations never";
      cc =
        "${pkgs.clang}/bin/clang -Wall -Wextra -pedantic -std=c99 -Wshadow -Weverything";
      qr = "${pkgs.qrencode}/bin/qrencode -t utf8 -o-";
      top = "${pkgs.htop}/bin/htop";
      weather = "${pkgs.curl}/bin/curl -4 http://wttr.in/Koeln";
      radio = "${pkgs.mpv}/bin/mpv http://lassul.us:8000/radio.ogg";

      yotp = ''
        ${pkgs.yubikey-manager}/bin/ykman oath accounts code | \
         ${pkgs.fzf}/bin/fzf | awk '{print $2}' | ${pkgs.xclip}/bin/xclip -sel clip
      '';

      zzz = "systemctl suspend";

      serve = "${pkgs.dirserver}/bin/dirserver";
      # "nix-shell -p python38Packages.httpcore --run 'python -m http.server 8080'";

      za = "${./zellij-chooser}";

      upterm = "${pkgs.upterm}/bin/upterm host --server ssh://upterm.thalheim.io:2323 --force-command 'zellij attach pair-programming' -- zellij attach --create pair-programming";
    };

    prezto = {
      enable = true;
      prompt.theme = "pure";

      # Case insensitive completion
      caseSensitive = false;

      # Autoconvert .... to ../..
      editor.dotExpansion = true;

      # Prezto modules to load
      # pmodules = [ "utility" "editor" "directory" "completion"];
      pmodules = [ "utility" "editor" "directory" "prompt" ];

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
      {
        name = "forgit";
        file = "forgit.plugin.zsh";
        src = "${pkgs.forgit}/share/forgit";
      }
    ];
  };
}
