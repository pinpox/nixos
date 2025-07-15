{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.programs.taskwarrior;
in
{
  options.pinpox.programs.taskwarrior.enable = mkEnableOption "takswarrior configuration";

  config = mkIf cfg.enable {

    programs.taskwarrior = {
      package = pkgs.taskwarrior3;

      # colorTheme	Either one of the default provided theme as string, or a path to a theme configuration file. 	null or string or path
      # config	Key-value configuration written to {file}`$XDG_CONFIG_HOME/task/taskrc`. 	attribute set of anything
      enable = true;
      # extraConfig	Additional content written at the end of {file}`$XDG_CONFIG_HOME/task/taskrc`. 	strings concatenated with "\n"
    };
  };
}
