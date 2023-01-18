# { lib, callPackage, fetchFromGitHub, fetchYarnDeps, mkYarnPackage, inputs }:
# let
#   version = "git";
#   # yarnSha256 = "";
# in
# mkYarnPackage {
#   pname = "woodpecker-frontend";



#   packageJSON = ./woodpecker-package.json;
#   # offlineCache = fetchYarnDeps {
#   #   yarnLock = "${inputs.pinpox-woodpecker}/web/yarn.lock";
#   #   sha256 = yarnSha256;
#   # };


#   # Do not attempt generating a tarball for woodpecker-frontend again.
#   doDist = false;

# }

{ lib
, fetchFromGitHub
, pkgs
, stdenv
, nodejs
, inputs
}:

stdenv.mkDerivation rec {
  pname = "woodpecker-frontend-next";
  version = "git";


  src = "${inputs.pinpox-woodpecker}/web";

  nativeBuildInputs = [
    nodejs
  ];

  buildPhase =
    let
      nodeDependencies = ((import ./node-composition.nix {
        inherit pkgs nodejs;
        inherit (stdenv.hostPlatform) system;
      }).nodeDependencies.override (old: {
        # access to path '/nix/store/...-source' is forbidden in restricted mode
        src = src;

        # dont run the prepare script:
        # Error: Cannot find module '/nix/store/...-node-dependencies-jellyfin-web-.../jellyfin-web/scripts/prepare.js
        # npm run build:production runs the same command
        dontNpmInstall = true;
      }));
    in
    ''
      runHook preBuild
      ln -s ${nodeDependencies}/lib/node_modules ./node_modules
      export PATH="${nodeDependencies}/bin:$PATH"
      npm run build
      runHook postBuild
    '';


  # buildPhase = ''
  #   runHook preBuild

  #   pnpm build

  #   runHook postBuild
  # '';

  installPhase = ''
    runHook preInstall

    cp -R deps/woodpecker-ci/dist $out
    echo "${version}" > "$out/version"

    runHook postInstall
  '';

  # installPhase = ''
  #   runHook preInstall
  #   mkdir -p $out/share
  #   cp -a dist $out/share/jellyfin-web
  #   runHook postInstall
  # '';


}
