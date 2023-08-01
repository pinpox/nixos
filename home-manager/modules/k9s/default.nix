{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.pinpox.programs.k9s;
in
{

  options.pinpox.programs.k9s.enable = mkEnableOption "k9s kubernetes CLI";

  config = mkIf cfg.enable {

    home.packages = [ pkgs.k9s ];

    xdg = {
      enable = true;
      configFile.k9s_theme = {
        target = "k9s/skin.yml";
        text = builtins.toJSON {
          k9s = {
            body = {
              fgColor = "#cad3f5";
              bgColor = "#24273a";
              logoColor = "#cba6f7";
            };
            info = {
              fgColor = "#74c7ec";
              sectionColor = "#8aadf4";
            };
            frame = {
              border = {
                fgColor = "#cba6f7";
                focusColor = "#f5bde6";
              };
              menu = {
                fgColor = "#eed49f";
                keyColor = "#8aadf4";
                numKeyColor = "#f5bde6";
              };
              crumbs = {
                fgColor = "#cad3f5";
                bgColor = "#8aadf4";
                activeColor = "#74c7ec";
              };
              status = {
                newColor = "#a6da95";
                modifyColor = "#68f288";
                addColor = "#74c7ec";
                errorColor = "#ed8796";
                highlightcolor = "#8aadf4";
                killColor = "#747c9e";
                completedColor = "#5b6078";
              };
              title = {
                fgColor = "#8bd5ca";
                bgColor = "#5b6078";
                highlightColor = "#74c7ec";
                counterColor = "#cba6f7";
                filterColor = "#5b6078";
              };
            };
            views = {
              table = {
                fgColor = "#cad3f5";
                bgColor = "#24273a";
                cursorColor = "#8bd5ca";
                header = {
                  fgColor = "#24273a";
                  bgColor = "#8aadf4";
                };
              };
              yaml = {
                keyColor = "#8bd5ca";
                colonColor = "#aee2da";
                valueColor = "#a6da95";
              };
              logs = {
                fgColor = "#cad3f5";
                bgColor = "#24273a";
              };
            };
          };
        };
      };
    };
  };
}
