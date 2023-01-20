{ lib, buildGoModule, callPackage, fetchFromGitHub, inputs }:
buildGoModule {
  pname = "woodpecker-plugin-git";
  name = "woodpecker-plugin-git";
  vendorSha256 = "sha256-63Ly/9yIJu2K/DwOfGs9pYU3fokbs2senZkl3MJ1UIY=";

  src = inputs.woodpecker-plugin-git;

  doCheck = false;

  # postBuild = ''
  #   cd $GOPATH/bin
  #   for f in *; do
  #     mv -- "$f" "woodpecker-$f"
  #   done
  #   cd -
  # '';

  # ldflags = [
  #   "-s"
  #   "-w"
  #   "-X github.com/woodpecker-ci/woodpecker/version.Version=${version}"
  # ];


  # subPackages = "cmd/agent";

  CGO_ENABLED = 0;

}


