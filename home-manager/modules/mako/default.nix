{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.mako;
in
{
  options.pinpox.programs.mako.enable = mkEnableOption "mako notifications";

  config = mkIf cfg.enable {


    # Needed for firefox and thunderbird
    home.packages = [ pkgs.libnotify ];

    services.mako = {
      enable = true;
      anchor = "top-right";
      backgroundColor = "#285577FF";
      borderColor = "#4C7899FF";
      # progressColor = "over #5588AAFF";
      textColor = "#FFFFFFFF";
      borderRadius = 5;
      borderSize = 5;
      defaultTimeout = 10000; # In milliseconds
      # extraConfig = '''';
      font = "Berkeley Mono 12";
      # %a   Application name
      # %s   Notification summary
      # %b   Notification body
      # %g   Number of notifications in the current group
      # %i   Notification id
      # format = "<b>%s</b>\\n%b";
      # groupBy = "";
      height = 200;
      width = 300;
      # iconPath = "";
      icons = true;
      margin = "10";
      padding = "5";
    };
  };
}
