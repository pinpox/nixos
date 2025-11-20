{ config, lib, ... }:
with lib;
let
  cfg = config.pinpox.programs.go;
in
{
  options.pinpox.programs.go.enable = mkEnableOption "go compiler";

  config = mkIf cfg.enable {

    programs = {
      go = {
        enable = true;
        env.GOPATH = "/home/pinpox/.go";
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
