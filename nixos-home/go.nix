{ config, pkgs, lib, ... }: {
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
}
