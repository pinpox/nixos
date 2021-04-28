{ pkgs, lib, stdenv, requireFile, unzip }:

stdenv.mkDerivation {

  pname = "monego";
  version = "2021-03-31";
  src = pkgs.fetchFromGitHub {
    owner = "cseelus";
    repo = "monego";
    rev = "3f6c2984c97dd7622f997aa9e6ea0537aaa6a6be";
    sha256 = "sha256-7qQxGDLnpGCRPRJ9SJneiD2/Vb/bYs6Q2zo4XaVdMs8=";
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/share/fonts/OTF
    cp -a * "$out"/share/fonts/OTF/
  '';

  meta = with lib; {
    description =
      "The beloved Monaco monospaced font, recreated with bold and italic variants";
    longDescription = ''
      Bold and italic variants of Monaco were originally recreated by @vjpr but
      seem to be abandoned now. Font integration problems were fixed by me.
      Bold-italic version by @kokoko3k.
          '';
    homepage = "https://github.com/cseelus/monego";
    license = licenses.unfree;
    maintainers = with maintainers; [ pinpox ];
    platforms = platforms.all;
  };
}
