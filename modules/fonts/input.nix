{ lib, stdenv, requireFile, unzip }:

stdenv.mkDerivation {
  pname = "input-custom";
  version = "date"; # date of the download and checksum

  src = ./input450.zip;
  # requireFile {
  #   name = "Input-Font.zip";
  #   url = "file://Input-Font.zip";
  #   sha256 = "11rax2a7vzidcs7kyfg5lv5bwp9i7kvjpdcsd10p0517syijkp3b";
  # };

  nativeBuildInputs = [ unzip ];

  phases = [ "unpackPhase" "installPhase" ];

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    find Input_Fonts -name "*.ttf" -exec cp -a {} "$out"/share/fonts/truetype/ \;
    mkdir -p "$out"/share/doc
    cp -a *.txt "$out"/share/doc/
  '';

  outputHashAlgo = "sha256";
  outputHashMode = "recursive";
  # outputHash = "sha256-kSDG4g29pzyO4ugIqPy3CzEVKlCfHA6qlEOpKISnM/I=";
# outputHash = "sha256-fW5Ur0qjEBqpSEwUi7Ks8DP8VVDiTheGiPD3urbZIns="; # input400.zip
# outputHash = "sha256-UWszhDoVCovKWuNbY/FEC33nf7C5FbfAUuZyGOXPrXM="; # input500.zip
outputHash = "sha256-g3fY691IKNXaSHrdKfZFzFPIQUoyuzwk5foXqKDcsso="; # input450.zip

  meta = with lib; {
    description = "Fonts for Code, from Font Bureau (Customized Version)";
    longDescription = ''
      Input is a font family designed for computer programming, data,
      and text composition. It was designed by David Jonathan Ross
      between 2012 and 2014 and published by The Font Bureau. It
      contains a wide array of styles so you can fine-tune the
      typography that works best in your editing environment.

      Input Mono is a monospaced typeface, where all characters occupy
      a fixed width. Input Sans and Serif are proportional typefaces
      that are designed with all of the features of a good monospace —
      generous spacing, large punctuation, and easily distinguishable
      characters — but without the limitations of a fixed width.
    '';
    homepage = "https://input.fontbureau.com";
    license = licenses.unfree;
    maintainers = with maintainers; [ romildo ];
    platforms = platforms.all;
  };
}
