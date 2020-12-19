{ stdenv, glibc, gcc-unwrapped, autoPatchelfHook }:
let

  # Please keep the version x.y.0.z and do not update to x.y.76.z because the
  # source of the latter disappears much faster.
  version = "3.7.6";

  # https://mmonit.com/dist/mmonit-3.7.6-linux-x64.tar.gz

in stdenv.mkDerivation {

  name = "mmonit";

  system = "x86_64-linux";

  src =
    fetchTarball "https://mmonit.com/dist/mmonit-${version}-linux-x64.tar.gz";

  nativeBuildInputs = [
    autoPatchelfHook # Automatically setup the loader, and do the magic
  ];

  # Extract and copy executable in $out/bin
  installPhase = ''
    mkdir -p $out
    cp -av $src/* $out
  '';

  meta = with stdenv.lib; {
    description = "m/monit monitoring";
    homepage = "https://mmonit.com/";
    license = licenses.mit;
    maintainers = with stdenv.lib.maintainers; [ pinpox ];
    platforms = [ "x86_64-linux" ];
  };
}
