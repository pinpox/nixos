{ lib, buildGoModule }:

buildGoModule rec {
  pname = "dirserver";
  version = "1.0.0";

  vendorSha256 = null;

  src = ./src;

  meta = with lib; {
    maintainers = with maintainers; [ pinpox ];
    license = licenses.mit;
    description = "Serve a dir";
  };
}
