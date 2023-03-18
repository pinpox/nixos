{ lib, fetchFromGitHub, buildGoModule, enableUnfree ? true }:

buildGoModule rec {
  pname = "drone.io";
  version = "2.16.0";

  vendorSha256 = "sha256-9EKXMy9g3kTpHer27ouuFDjh7zSEeBcpI8nH1VkMA9M=";

  doCheck = false;

  src = fetchFromGitHub {
    owner = "drone";
    repo = "drone";
    rev = "v${version}";
    sha256 = "sha256-bNvXAcFMPK8C/QN7VTdnicewRfaEtyJ45MhQSTNYp3U=";
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
