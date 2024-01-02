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

        ignores = [ "tags" "*.swp" ];

        extraConfig = {
          # Possibly change this to "main" when majority of projects have
          # switched branch names
          init.defaultBranch = "master";

          pull.rebase = false;
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
          co = "checkout";
        };

        userEmail = "mail@pablo.tools";
        userName = "Pablo Ovelleiro Corral";
      };
    };
  };
}
