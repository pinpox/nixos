# Memories for Nextcloud 35. nixpkgs only packages Memories 8.1.0, which stops
# at Nextcloud 34. Adapted from nixpkgs' pkgs/servers/nextcloud/packages/apps/memories.nix.
# TODO: drop once nextcloud35.packages.apps.memories exists in nixpkgs.
{
  lib,
  stdenv,
  buildGo127Module,
  fetchurl,
  fetchFromGitHub,
  exiftool,
  ffmpeg-headless,
}:
let
  version = "10.1.0";

  # Must match GOVOD_VER in lib/Service/BinExt.php; Memories refuses other
  # versions. go.mod requires Go >= 1.27.
  go-vod = buildGo127Module (finalAttrs: {
    pname = "go-vod";
    version = "0.6.3";
    src = fetchFromGitHub {
      owner = "pulsejet";
      repo = "memories";
      tag = "v${version}";
      hash = "sha256-JByYsrLsrzX0yi1DsRUnFfUhTC6HbvkPGRURwAZ56D0=";
    };
    sourceRoot = "${finalAttrs.src.name}/go-vod";
    vendorHash = "sha256-2MD8zRu2aLn2klqEgprr48rNNGvtj37JlKYHwbVioRg=";
    meta.mainProgram = "go-vod";
  });

  # Binaries are pinned to the Nix store; the admin UI cannot change them.
  nixPaths = {
    "memories.exiftool" = lib.getExe exiftool;
    "memories.exiftool_no_local" = false;
    "memories.vod.ffmpeg" = lib.getExe ffmpeg-headless;
    "memories.vod.ffprobe" = lib.getExe' ffmpeg-headless "ffprobe";
    "memories.vod.path" = lib.getExe go-vod;
  };
  # PHP array literal; JSON scalars are valid PHP and avoid single quotes,
  # which would end the shell quoting in postPatch.
  phpNixPaths = "[${
    lib.concatStringsSep ", " (
      lib.mapAttrsToList (k: v: "${builtins.toJSON k} => ${builtins.toJSON v}") nixPaths
    )
  }]";
in
stdenv.mkDerivation {
  pname = "nextcloud-app-memories";
  inherit version;

  src = fetchurl {
    url = "https://github.com/pulsejet/memories/releases/download/v${version}/memories.tar.gz";
    hash = "sha256-tbR2ts19fXoW8hkUF1LIoA4tQO6WQWJvNjG/gnWUlw8=";
  };

  postPatch = ''
    rm appinfo/signature.json
    rm -rf bin-ext/

    substituteInPlace lib/Service/BinExt.php \
      --replace-fail "EXIFTOOL_VER = '13.59'" "EXIFTOOL_VER = '${exiftool.version}'"

    substituteInPlace lib/Settings/SystemConfig.php \
      --replace-fail \
        '        // Use the default value if not provided' \
        '        if (\array_key_exists($key, ${phpNixPaths})) { return ${phpNixPaths}[$key]; }
            // Use the default value if not provided' \
      --replace-fail \
        '        // Key belongs to memories namespace' \
        '        if (\array_key_exists($key, ${phpNixPaths})) { throw new \InvalidArgumentException("Cannot set nix-managed key: {$key}"); }
            // Key belongs to memories namespace'
  '';

  installPhase = ''
    mkdir -p $out
    cp -r ./* $out/
  '';

  meta = {
    description = "Fast, modern and advanced photo management suite";
    homepage = "https://apps.nextcloud.com/apps/memories";
    license = lib.licenses.agpl3Only;
  };
}
