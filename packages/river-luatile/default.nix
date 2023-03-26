{ lib
, fetchFromGitHub
, openssl
, luajit
, pkg-config
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "river-luatile";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "MaxVerevkin";
    repo = pname;
    fetchSubmodules = true;
    rev = "v${version}";
    sha256 = "sha256-A8vx8jN4XUUI970ZsWLKBCd5lO9p3w63b9EiGwk/rCU=";
  };

  cargoSha256 = "sha256-udfsd1iONlDSQ/7mzzRNNhoJHmXJsxWdhqeKK/onx+4=";

  buildInputs = [ luajit ];
  nativeBuildInputs = [ pkg-config ];
  PKG_CONFIG_PATH = "${openssl.dev}/lib/pkgconfig";

  meta = with lib; {
    homepage = "https://github.com/MaxVerevkin/river-luatile";
    description = "Write your own river layout generator in lua";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ pinpox ];
  };
}
