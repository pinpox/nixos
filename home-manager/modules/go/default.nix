{ config, pkgs, lib, nur, utils, ... }:
with lib;
let
  vars = import ../vars.nix;
  cfg = config.pinpox.programs.go;
in
{
  options.pinpox.programs.go.enable = mkEnableOption "go compiler";

  config = mkIf cfg.enable {

    programs = {
      go = {
        enable = true;
        goPath = ".go";
        #      packages = {
        #        "golang.org/x/text" =
        #          builtins.fetchGit "https://go.googlesource.com/text";
        #        "golang.org/x/time" =
        #          builtins.fetchGit "https://go.googlesource.com/time";
        #      };
      };
    };
  };
}
