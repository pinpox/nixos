{ config, lib, ... }:
with lib;
let

  cfg = config.pinpox.programs.pandoc;
in
{
  options.pinpox.programs.pandoc.enable = mkEnableOption "pandoc config";

  config = mkIf cfg.enable {

    programs.pandoc = {
      enable = true;
      citationStyles = [ ];

      # templates = {
      # "default.latex" = path/to/your/template;
      # };

      defaults = {
        metadata = {
          author = "Pablo Ovelleiro Corral";
        };
        # pdf-engine = "xelatex";
        # citeproc = true;
      };
    };

  };
}
