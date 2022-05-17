{ lib
, stdenv
, fetchurl
, ...
}:
stdenv.mkDerivation rec {
  name = "filebrowser";
  version = "v2.15.0";
  src = fetchurl {
    # TODO use flake inputs
    url = "https://github.com/filebrowser/filebrowser/releases/download/${version}/linux-amd64-filebrowser.tar.gz";
    sha256 = "0ryh35n0z241sfhcnwac0qa1vpxdn8bnlpw4kqhz686mvnr1p1x4";
  };

  # Work around the "unpacker appears to have produced no directories"
  # case that happens when the archive doesn't have a subdirectory.
  setSourceRoot = "sourceRoot=`pwd`";

  installPhase = ''
    mkdir -p $out/bin
    cp filebrowser "$out"/bin/filebrowser
  '';
}
