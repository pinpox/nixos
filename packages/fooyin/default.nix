# fooyin 0.13.1 with public development headers + FooyinConfig.cmake, so
# out-of-tree plugins (e.g. foonic) can be built against it.
# TODO: drop the version bump once nixpkgs has fooyin >= 0.13.1.
{
  fooyin,
  fetchFromGitHub,
  lib,
}:
fooyin.overrideAttrs (old: {
  version = "0.13.1";

  src = fetchFromGitHub {
    owner = "fooyin";
    repo = "fooyin";
    tag = "v0.13.1";
    hash = "sha256-HinvM2lB8CQhYNJjXt5ZVR2cw2hfVpKbtKG0BzmirCs=";
  };

  cmakeFlags = old.cmakeFlags ++ [
    (lib.cmakeBool "INSTALL_HEADERS" true)
    # Exported targets prepend $<INSTALL_PREFIX> to the include dir; nixpkgs'
    # absolute default would yield $out//nix/store/... in FooyinTargets.cmake.
    (lib.cmakeFeature "CMAKE_INSTALL_INCLUDEDIR" "include")
  ];
})
