with import <nixpkgs> { };

stdenv.mkDerivation rec {
  name = "blog";

  # src = ./git-repos/hugo-website;
  src = builtins.fetchurl { url = "https://github.com/pinpox/hugo-website/archive/main.tar.gz"; };

  buildInputs = [ hugo ];
  buildPhase = "hugo";
  installPhase = "cp -R public/ $out";
}
