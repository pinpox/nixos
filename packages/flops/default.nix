{ stdenv, pkgs }:
pkgs.writeShellScriptBin "deploy" ''
  echo "Deploying: $1"
''
