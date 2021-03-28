{ pkgs, ... }:

let
  scriptDeps = [ pkgs.jq pkgs.borgbackup ];

  borg-monitor-repo = pkgs.runCommandLocal "borg-monitor-repo" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    mkdir -p "$out/bin"
    cp "${./borg-check.sh}" "$out/bin/borg-monitor-repo"
    patchShebangs "$out/bin/borg-monitor-repo"
    wrapProgram "$out/bin/borg-monitor-repo" \
      --prefix PATH : "${pkgs.lib.makeBinPath scriptDeps}"
  '';

in { environment.systemPackages = [ borg-monitor-repo ]; }
