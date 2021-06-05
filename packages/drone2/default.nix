{ lib, fetchFromGitHub, buildGoModule
, enableUnfree ? true }:

buildGoModule rec {
  pname = "drone.io${lib.optionalString (!enableUnfree) "-oss"}";
  version = "2.0.1";

  vendorSha256 = "sha256-cnbZSnHU+ORm7/dV+U9NfM18Zrzi24vf7qITPJsusU8=";

  doCheck = false;

  src = fetchFromGitHub {
    owner = "drone";
    repo = "drone";
    rev = "v${version}";
    sha256 = "sha256-kXIy3VmRFsY7fCu3m3Hyr8LynIhOTsnOZUWv5zJqXJc=";
  };

  preBuild = ''
    buildFlagsArray+=( "-tags" "${lib.optionalString (!enableUnfree) "oss nolimit"}" )
  '';

  meta = with lib; {
    maintainers = with maintainers; [ elohmeier vdemeester ];
    license = with licenses; if enableUnfree then unfreeRedistributable else asl20;
    description = "Continuous Integration platform built on container technology";
  };
}
