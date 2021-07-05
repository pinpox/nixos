{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.programs.tmux;
in {
  options.pinpox.programs.tmux.enable =
    mkEnableOption "tmux terminal mutliplexer";

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      clock24 = true;
      prefix = "C-a";
      newSession = true;
    };
  };
}
