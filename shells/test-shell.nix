{ pkgs }:
with pkgs;
mkShell {
  buildInputs = [ nixpkgs-fmt ];

  shellHook = ''
    echo "Hello world"
  '';
}
