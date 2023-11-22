{ lib, fetchFromGitHub, buildGoModule, pkgs }:

buildGoModule rec {
  pname = "fritzbox_exporter";
  version = "latest";

  # vendorHash = null;
  vendorHash = "sha256-jcHJNTdiYRQcjJr9VcABY5Ark4bmzqsJcn1iMW09Xl0=";

  nativeBuildInputs = with pkgs; [ pkg-config ];

  # Updated 2022-01-11
  src = fetchFromGitHub {
    owner = "sberk42";
    repo = "fritzbox_exporter";
    rev = "baa6961be43256af0d904642492e016a35f2a135";
    sha256 = "sha256-ANK8sIHn2vx5+XJ0c6U2uQQiDBYhTfQ65RASdXPtF7w=";
  };

  meta = with lib; {
    maintainers = with maintainers; [ pinpox ];
    license = licenses.asl20;
    description = "Fritzbox exporter for prometheus";
  };
}
