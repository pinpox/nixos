{ lib, buildGoModule, callPackage, fetchFromGitHub, pkgs, inputs }:

let
  version = "git";
  woodpecker-frontend = pkgs.callPackage ./frontend.nix { };
in
buildGoModule {
  pname = "woodpecker-server-next";
  name = "woodpecker-server-next";

  vendorSha256 = "sha256-ZavlAFfHshXDdIq7uyNMtdJS4hmVil4ZdipF0pXnIRU=";


  src = inputs.pinpox-woodpecker;

  postPatch = ''
    cp -r ${woodpecker-frontend} web/dist
  '';

  subPackages = "cmd/server";

  postBuild = ''
    cd $GOPATH/bin
    for f in *; do
      mv -- "$f" "woodpecker-$f"
    done
    cd -
  '';

  ldflags = [
    "-s"
    "-w"
    "-X github.com/woodpecker-ci/woodpecker/version.Version=${version}"
  ];


  CGO_ENABLED = 1;

  passthru = {
    inherit woodpecker-frontend;
    updateScript = ./update.sh;
  };

}
