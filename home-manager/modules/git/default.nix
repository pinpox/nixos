{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.defaults.git;
in
{
  options.pinpox.defaults.git.enable = mkEnableOption "git defaults";

  config = mkIf cfg.enable {

    home.packages = with pkgs; [ tig ];

    programs = {

      lazygit = {
        enable = true;

        # https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md
        settings = {

          # reporting = "off";
          # update.method = "never";

          shortTimeFormat = "15h:30:13";
          gui.showFileTree = true;
          os = {
            edit = "nvim {{filename}}";
            editAtLine = "nvim +{{line}} {{filename}}";
            editAtLineAndWait = "nvim --remote-wait +{{line}} {{filename}}";
            editInTerminal = true;
          };
        };
      };

      git = {
        enable = true;
        lfs.enable = true;

        ignores = [
          "tags"
          "*.swp"
          "result"
          ".claude"
        ];

        settings = {

          extraConfig = {
            init.defaultBranch = "main";

            pull = {
              rebase = true;
              autostash = true;
              twohead = "ort";
            };

            push = {
              default = "simple";
              autoSetupRemote = true;
            };

            # rerere = {
            #   autoUpdate = true
            #   enabled = true
            # };

            branch = {
              autoSetupRebase = "always";
              autoSetupMerge = "always";
            };

            rebase = {
              stat = true;
              autoStash = true;
              autoSquash = true;
              updateRefs = true;
            };

            help.autocorrect = 10;
          };

          signing = {
            format = "ssh";
            key = "~/.ssh/key.pub";
            signByDefault = true;
          };

          aliases = {
            s = "status";
            d = "diff";
            a = "add";
            c = "commit";
            p = "push";
            o = "checkout";
            co = "checkout";
            uncommit = "reset --soft HEAD^";
            comma = "commit --amend";
            reset-pr = "reset --hard FETCH_HEAD";
            force-push = "push --force-with-lease";
          };

          user.email= "git@pablo.tools";
          user.name = "pinpox";
        };
      };
    };

    # [kiwi] evaluation warning: pinpox profile: The option `programs.git.aliases' defined in `/nix/store/fsc89mqrbiij6pnl4vrf0l0plv0i8pp6-source/clan-service-modules/machine-type/desktop.nix' has been renamed to `programs.git.settings.alias'.
    # [kiwi] evaluation warning: pinpox profile: The option `programs.git.extraConfig' defined in `/nix/store/fsc89mqrbiij6pnl4vrf0l0plv0i8pp6-source/clan-service-modules/machine-type/desktop.nix' has been renamed to `programs.git.settings'.

    programs.jujutsu = {
      enable = true;
      settings = {
        merge-tools.meld.merge-args = [
          "$left"
          "$base"
          "$right"
          "-o"
          "$output"
          "--auto-merge"
        ];
        signing = {
          behavior = "own";
          backend = "ssh";
          key = "~/.ssh/key.pub";
          allowed-signers = "~/.ssh/allowed_signers";
        };
        ui = {
          default-command = "log";
          merge-editor = [
            "meld"
            "$left"
            "$base"
            "$right"
            "-o"
            "$output"
          ];
        };
        user = {
          email = "git@pablo.tools";
          name = "pinpox";
        };
      };
    };
  };
}
