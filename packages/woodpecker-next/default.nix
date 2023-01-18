{ lib, buildGoModule, callPackage, fetchFromGitHub, inputs }:
let
  # common = callPackage ./common.nix {inherit inputs; };
  version = "git";
in
buildGoModule {
  pname = "woodpecker-agent-next";
  name = "woodpecker-agent-next";
  vendorSha256 = "sha256-ZavlAFfHshXDdIq7uyNMtdJS4hmVil4ZdipF0pXnIRU=";

  src = inputs.pinpox-woodpecker;

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


  subPackages = "cmd/agent";

  CGO_ENABLED = 0;

}
