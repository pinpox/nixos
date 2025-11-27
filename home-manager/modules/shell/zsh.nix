{
  flake-inputs,
  pkgs,
  promterm,
  lib,
  config,
  ...
}:
{

  programs.zsh = {
    enable = true;
    autosuggestion = {
      enable = true;
      highlight = "fg=8";
    };
    enableCompletion = true;
    autocd = true;
    dotDir = "${config.xdg.configHome}/zsh";
    sessionVariables = {
      RPS1 = ""; # Disable the right side prompt that "walters" theme introduces
      ZDOTDIR = "/home/pinpox/.config/zsh";
    };

    initContent =
      let
        abbrevs = lib.concatStrings (
          map (
            a:
            let
              opt = lib.strings.optionalString;
            in
            ''
              abbrev-alias ${opt a.global "-g "}${opt a.eval "-e "}${opt a.recursive "-r "}${a.alias}="${a.command}"
            ''
          ) config.pinpox.defaults.shell.abbrev-aliases
        );

        functions = ''
          function "="() { printf "%s\n" "$@" | ${pkgs.bc}/bin/bc }

          function ai() {
            echo "$@" | $##{pkgs.shell-gpt}/bin/sgpt
          }

          function aip() {
            wl-paste | $##{pkgs.shell-gpt}/bin/sgpt
          }

          # Create a temporary, detached worktree of the current git repo.
          # Great for quick hot-fixes.
          twork () {
              local wtpath="$(mktemp -d)"
              git worktree add --detach $wtpath
              cd $wtpath
          }

          # Jump to a code project with FZF using Ctrl+j
          fzf_cd_widget() {
            local base="/home/pinpox/code"
            local rel full

            rel=$(
              find "$base" -maxdepth 3 -type d \
                | grep -E '(/.*){6}' \
                | sed "s|^$base/||" \
                | fzf --preview "BASE=$base sh -c '${pkgs.eza}/bin/eza \
                  --group-directories-first --tree --level=2 --icons \"\$BASE/\$0\"' {}"
            ) || return

            full="$base/$rel"
            cd "$full" || return

            if [[ -n "$ZLE_NAME" ]]; then
              zle reset-prompt
            fi
          }

          zle -N fzf_cd_widget
          bindkey '^J' fzf_cd_widget

          # Power profile function using ryzenadj
          power-profile() {
          if [ $# -ne 4 ]; then
            echo "Usage: power-profile <name> <stapm> <fast> <slow>"
            echo "Example: power-profile PERFORMANCE 30000 35000 35000"
            return 1
          fi

          local name=$1
          local stapm=$2 # Sustained power limit
          local fast=$3 # Short burst power limit (instant peak response)
          local slow=$4 # Slow burst power limit (~5-10s)

          sudo ${lib.getExe pkgs.ryzenadj} --stapm-limit=$stapm --fast-limit=$fast --slow-limit=$slow && \
            echo "Power profile set to: $name (''${stapm}mW/''${fast}mW/''${slow}mW)"
          }

        '';
      in
      lib.mkMerge [
        (lib.mkOrder 550 (builtins.readFile ./zshrc))
        abbrevs
        (builtins.readFile ./zshrc-extra)
        (builtins.readFile ./zshrc-coffee)
        functions
      ];

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
      downloads = "$HOME/Downloads";
      nix-config = "/home/pinpox/code/github.com/pinpox/nixos";
      clan = "$HOME/code/git.clan.lol/clan/clan-core";
      clan-infra = "$HOME/code/git.clan.lol/clan/clan-infra";
    };

    shellAliases = rec {

      gif = "${flake-inputs.gif-searcher.packages.x86_64-linux.default}/bin/show-gif";
      gifi = "${flake-inputs.gif-searcher.packages.x86_64-linux.gif-infinite}/bin/show-gif";

      remote-review = ''nixpkgs-review pr --build-args="--builders 'ssh://pinpox@build-box.nix-community.org'"'';

      # eza ls replacement
      ls = "${pkgs.eza}/bin/eza --group-directories-first";
      l = "${ls} -lbF --git --icons";
      ll = "${l} -G";
      la = "${ls} -lbhHigmuSa@ --time-style=long-iso --git --color-scale --icons";
      lt = "${ls} --tree --level=2 --icons";

      nb = "nix build --no-link --print-out-paths -L";
      ne = "nix eval --strict --json";

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
      cc = "${pkgs.clang}/bin/clang -Wall -Wextra -pedantic -std=c99 -Wshadow -Weverything";
      qr = "${pkgs.qrencode}/bin/qrencode -t utf8 -o-";
      top = "${pkgs.htop}/bin/htop";
      weather = "${pkgs.curl}/bin/curl -4 http://wttr.in/Koeln";
      radio = "${pkgs.mpv}/bin/mpv http://lassul.us:8000/radio.ogg";

      # ${pkgs.yubikey-manager}/bin/ykman oath accounts code | \
      yotp = ''
        ${pkgs.fzf}/bin/fzf | awk '{print $2}' | ${pkgs.xclip}/bin/xclip -sel clip
      '';

      zzz = "systemctl suspend";

      serve = "${pkgs.miniserve}/bin/miniserve";

      za = "${./zellij-chooser}";

      upterm = "${pkgs.upterm}/bin/upterm host --server ssh://upterm.thalheim.io:2323 --force-command 'zellij attach pair-programming' -- zellij attach --create pair-programming";

      # Power profile aliases
      power-performance = "power-profile PERFORMANCE 30000 35000 35000";
      power-balanced = "power-profile BALANCED 25000 33000 33000";
      power-saver = "power-profile POWER-SAVER 26000 30000 15000";
      power-ultra-saver = "power-profile ULTRA-POWER-SAVER 10000 20000 10000";

    };

    prezto = {
      enable = true;
      # prompt.theme = "pure";

      # Case insensitive completion
      caseSensitive = true;

      # Autoconvert .... to ../..
      editor.dotExpansion = true;

      # Prezto modules to load
      # pmodules = [ "utility" "editor" "directory" "completion"];
      pmodules = [
        "utility"
        "editor"
        "directory"
        # "prompt"
      ];

      terminal.autoTitle = true;
    };

    plugins = [
      {
        name = "zsh-forgit";
        src = pkgs.zsh-forgit;
        file = "share/zsh/zsh-forgit/forgit.plugin.zsh";
      }
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
        name = "zsh-async";
        file = "async.zsh";
        src = "${pkgs.zsh-async}/share/zsh-async";
      }
      {
        name = "jj-zsh-prompt";
        file = "jj-zsh-prompt.plugin.zsh";
        src = "${flake-inputs.jj-zsh-prompt.packages.${pkgs.system}.default}/share/jj-zsh-prompt";
      }
    ];
  };
}
