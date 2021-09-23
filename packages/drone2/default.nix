{ lib, fetchFromGitHub, buildGoModule, enableUnfree ? true }:

buildGoModule rec {
  pname = "drone.io";
  version = "2.4.0";

  vendorSha256 = "sha256-42+40NdzMQV8ZriydthrbYhxLohQWpupNivTc9IRApk=";

  doCheck = false;

  src = fetchFromGitHub {
    owner = "drone";
    repo = "drone";
    rev = "v${version}";
    sha256 = "sha256-YU0MEfiAC2/aCtjK59vo8AHkR68d8uv56yEu1PsAOUc=";
  };

  tags = [ "nolimit" ];

  meta = with lib; {
    maintainers = with maintainers; [ elohmeier vdemeester ];
    license = with licenses;
      if enableUnfree then unfreeRedistributable else asl20;
    description =
      "Continuous Integration platform built on container technology";
  };
}
