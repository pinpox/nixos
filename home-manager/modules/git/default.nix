{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.defaults.git;
in
{
  options.pinpox.defaults.git.enable = mkEnableOption "git defaults";

  config = mkIf cfg.enable {
    programs = {
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
          pull = {
            rebase = true;
            autostash = true;
            twohead = "ort";
          };

          push = {
            default = "simple";
            autoSetupRemote = true;
          };

          rerere = {
            #   autoUpdate = true
            #   enabled = true
          };

          # [branch]
          branch = {
            autoSetupRebase = "always";
            autoSetupMerge = "always";
          };

          # [rebase]
          rebase = {
            stat = true;
            autoStash = true;
            autoSquash = true;
            updateRefs = true;
          };

          help = {
            autocorrect = 10;
          };
        };

        signing = {
          key = "823A6154426408D3";
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

        userEmail = "mail@pablo.tools";
        userName = "Pablo Ovelleiro Corral";
      };
    };
  };
}
