{ pkgs, ... }:

let
  borg-monitor-repo = pkgs.writeScriptBin "borg-monitor-repo" (''
    #!${pkgs.stdenv.shell}
  '' + (builtins.readFile ./borg-check.sh));

in {
  environment.systemPackages = [ pkgs.jq pkgs.borgbackup borg-monitor-repo ];
}
