{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.defaults.git;
in
{
  options.pinpox.defaults.git.enable = mkEnableOption "git defaults";

  config = mkIf cfg.enable {

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
        ];

        extraConfig = {
          init.defaultBranch = "main";

          gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
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

        userEmail = "git@pablo.tools";
        userName = "pinpox";
      };
    };
  };
}
