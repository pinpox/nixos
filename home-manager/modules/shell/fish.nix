{ pkgs, promterm, ... }:
{

  programs = {

    fzf.enableFishIntegration = true;
    dircolors.enableFishIntegration = true;
    pazi.enableFishIntegration = true;
  };

  programs.fish = {
    enable = true;
    functions = {
      gitignore = "curl -sL https://www.gitignore.io/api/$argv";
      fish_command_not_found = "echo Did not find command $argv[1]";

      # # Create and change to a directory
      take = ''mkdir -p -- "$1" && cd -- "$1"'';

      # # Create and change to a new temporary directory
      ttake = "cd $(mktemp -d)";

      # # Use `line 10 /etc/hosts` to get 10th line of file
      line = ''awk "NR == $1" "$2"'';
    };

    plugins = [

      {

        # https://github.com/gazorby/fifc

        name = "fifc";
        src = pkgs.fetchFromGitHub {
          owner = "gazorby";
          repo = "fifc";
          rev = "a01650cd432becdc6e36feeff5e8d657bd7ee84a";
          sha256 = "sha256-Ynb0Yd5EMoz7tXwqF8NNKqCGbzTZn/CwLsZRQXIAVp4=";
        };
      }

    ];

    shellAbbrs = {

      o = "xdg-open";
      q = "exit";
      snvim = "sudo -E nvim";
      v = "nvim";

      # Global aliases, get expanded everywhere
      # abbrev-alias -g G = "| rg -i"
      # abbrev-alias - g P="| tb"
      #TODO
    };
    shellAliases = rec {

      # Eza ls replacement
      ls = "${pkgs.eza}/bin/eza --group-directories-first";
      l = "${ls} -lbF --git --icons";
      ll = "${l} -G";
      la = "${ls} -lbhHigmuSa@ --time-style=long-iso --git --color-scale --icons";
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
      cc = "${pkgs.clang}/bin/clang -Wall -Wextra -pedantic -std=c99 -Wshadow -Weverything";
      qr = "${pkgs.qrencode}/bin/qrencode -t utf8 -o-";
      top = "${pkgs.htop}/bin/htop";
      weather = "${pkgs.curl}/bin/curl -4 http://wttr.in/Koeln";
      radio = "${pkgs.mpv}/bin/mpv http://lassul.us:8000/radio.ogg";

      zzz = "systemctl suspend";

      serve = "${pkgs.miniserve}/bin/miniserve";

      za = "${./zellij-chooser}";

      upterm = "${pkgs.upterm}/bin/upterm host --server ssh://upterm.thalheim.io:2323 --force-command 'zellij attach pair-programming' -- zellij attach --create pair-programming";
    };
  };
}
