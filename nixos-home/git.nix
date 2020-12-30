{ config, pkgs, lib, ... }: {
  programs = {
    git = {
      enable = true;

      ignores = [ "tags" "*.swp" ];

      extraConfig = { pull.rebase = false; };

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
}
