{ pkgs, ... }:

let
  scriptDeps = [ pkgs.jq pkgs.borgbackup pkgs.bash ];

  borg-monitor-repo = pkgs.runCommandLocal "borg-monitor-repo" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    mkdir -p "$out/bin"
    makeWrapper "${./borg-check.sh}" "$out/bin/borg-monitor-repo" \
      --prefix PATH : "${pkgs.lib.makeBinPath scriptDeps}"
  '';

in {
  environment.systemPackages = [ borg-monitor-repo ];
}
