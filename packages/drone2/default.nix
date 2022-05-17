{ lib
, fetchFromGitHub
, buildGoModule
, enableUnfree ? true
,
}:
buildGoModule rec {
  pname = "drone.io";
  version = "2.10.0";

  vendorSha256 = "sha256-JWZCEKC4JMFhoZ8SsItNjkCrzSNfW6EyLEbtpThDxN0=";

  doCheck = false;

  src = fetchFromGitHub {
    owner = "drone";
    repo = "drone";
    rev = "v${version}";
    sha256 = "sha256-oGubP7e5pq6DOPOD22Tce2bYXMaVqHdveTrk9bvazek=";
  };

  tags = [ "nolimit" ];

  meta = with lib; {
    maintainers = with maintainers; [ elohmeier vdemeester ];
    license = with licenses;
      if enableUnfree
      then unfreeRedistributable
      else asl20;
    description = "Continuous Integration platform built on container technology";
  };
}
