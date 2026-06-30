{
  stdenv,
  lib,
  makeWrapper,
  bash,
  nix,
  jq,
  openssh,
  coreutils,
  gnugrep,
  gnused,
  hostname,
  ...
}:
stdenv.mkDerivation {
  pname = "config-hash";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp config-hash.sh $out/bin/config-hash
    chmod +x $out/bin/config-hash

    wrapProgram $out/bin/config-hash \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          nix
          jq
          openssh
          coreutils
          gnugrep
          gnused
          hostname
        ]
      }
  '';

  meta = {
    description = "Per-machine dirty/clean/offline detector: repo config vs deployed";
    mainProgram = "config-hash";
  };
}
