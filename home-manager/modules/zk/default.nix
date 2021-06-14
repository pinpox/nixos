{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.programs.zk;
in {
  options.pinpox.programs.zk.enable = mkEnableOption "zk zettelkasten client";

  config = mkIf cfg.enable {
    home.packages = with pkgs; [ zk ];

    programs.zsh = {

      sessionVariables.ZK_NOTEBOOK_DIR = "/home/pinpox/Notes";

      shellAliases = {
        # Edit interactively
        zke = "${pkgs.zk}/bin/zk edit --interactive";
      };
    };

    xdg = {
      enable = true;
      configFile = {

        # zk configuration file
        zk_config = {
          target = "zk/config.toml";
          source = ./config.toml;
        };

        # Template for default notes
        zk_template_default = {
          target = "zk/templates/default.md";
          source = ./default.md;
        };

        # Template for juornal/dairy notes
        zk_template_journal = {
          target = "zk/templates/journal.md";
          source = ./journal.md;
        };
      };
    };
  };
}
