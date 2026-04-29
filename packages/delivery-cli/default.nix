{
  python3,
  lib,
}:

python3.pkgs.buildPythonApplication {
  pname = "delivery-cli";
  version = "0.1.0";
  format = "other";

  src = ./.;

  dontBuild = true;

  installPhase = ''
    install -Dm755 delivery-cli.py $out/bin/delivery-cli
  '';

  meta = {
    description = "Track deliveries via the 17track API";
    license = lib.licenses.mit;
    mainProgram = "delivery-cli";
  };
}
