{ lib, config, pkgs, ... }:
with lib;
let cfg = config.pinpox.programs.tmux;
in
{
  options.pinpox.programs.tmux.enable =
    mkEnableOption "tmux terminal mutliplexer";

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;

      # Set the prefix key. Overrules the "shortcut" option when set.
      prefix = "C-a";

      # Automatically spawn a session if trying to attach and none are running.
      newSession = true;

      # Base index for windows and panes.
      baseIndex = 1;

      # Use 24 hour clock.
      clock24 = true;

      # Maximum number of lines held in window history.
      historyLimit = 8000;

      # Less command delay
      escapeTime = 20;

      # Set the $TERM variable.
      terminal = "screen-256color";

      plugins = with pkgs.tmuxPlugins; [
        tmux-fzf
      ];

      extraConfig = builtins.readFile ./tmux.conf;
    };
  };
}
