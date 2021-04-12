{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "wezterm-bin";
  version = "nightly-2021";

  src = fetchurl {
    url = "https://github.com/wez/wezterm/releases/download/nightly/wezterm-nightly.Ubuntu16.04.tar.xz";
    sha256 = "0ssi1wpaf7plaswqqjwigppsg5fyh99vdlb9kzl7c9lng89ndq1i";
  };


  doCheck = true;

  meta = with stdenv.lib; {
    description = "";
    longDescription = '' '';
    homepage = "";
    changelog = "";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.pinpox ];
    platforms = platforms.all;
  };
}
