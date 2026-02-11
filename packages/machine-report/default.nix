{
  stdenv,
  lib,
  makeWrapper,
  procps,
  coreutils,
  gawk,
  gnused,
  gnugrep,
  util-linux,
  iproute2,
  net-tools,
  hostname,
  acpi,
  ...
}:
stdenv.mkDerivation {
  pname = "machine-report";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp machine_report.sh $out/bin/machine-report
    chmod +x $out/bin/machine-report

    wrapProgram $out/bin/machine-report \
      --set LC_NUMERIC C \
      --prefix PATH : ${
        lib.makeBinPath [
          procps
          coreutils
          gawk
          gnused
          gnugrep
          util-linux
          iproute2
          net-tools
          hostname
          acpi
        ]
      }
  '';
}
