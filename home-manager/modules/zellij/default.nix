{ lib, config, pkgs, ... }:
with lib;
let cfg = config.pinpox.programs.zellij;
in
{
  options.pinpox.programs.zellij.enable =
    mkEnableOption "zellij terminal mutliplexer";

  config = mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      # settings = {}

      # {
      #   theme = "custom";
      #   themes.custom.fg = 5;
      # }

    };
  };
}
