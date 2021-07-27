{
  buildGoModule,
  fetchFromGitHub,
  pkg-config,
  glib,
  stdenv,
  vips,
  libraw,
  callPackage,
  nodejs,
  pkgs,
  system,
  ...
}:
let
  version = "1465e82368d408f6ecb47d663da389b7be785f30";

  source = fetchFromGitHub {
    owner = "pinpox";
    repo = "filestash";
    rev = "1465e82368d408f6ecb47d663da389b7be785f30";
    sha256 = "sha256-1Zu+zvwgLa0QfW/PUOmWFHCh5ScZsOZEFvuBXCDK31Y=";
  };

  js = ( let
  nodeDependencies = (pkgs.callPackage ({ pkgs, system }:
    let nodePackages = import ./generated { inherit pkgs system; };
    in nodePackages // {
      shell = nodePackages.shell.override {
        buildInputs = [ pkgs.nodePackages.node-gyp-build ];
      };
    }
    ) {}).shell.nodeDependencies;
    in
  stdenv.mkDerivation {
    name = "my-webpack-app";
    src = source;
    buildInputs = [nodejs];
    buildPhase = ''
      ln -s ${nodeDependencies}/lib/node_modules ./node_modules
      export PATH="${nodeDependencies}/bin:$PATH"

      # Build the distribution bundle in "dist"
      webpack
      cp -r dist $out/
    '';
    dontInstall = true;
  });


  tmp = stdenv.mkDerivation {
    pname = "tmp";
    version = "tmp";

    src = source;

    buildInputs = [
      vips
      libraw
      glib
    ];

    nativeBuildInputs = [
      pkg-config
    ];

    buildPhase = ''
      $CC -Wall -c $src/server/plugin/plg_image_light/deps/src/libresize.c `pkg-config --cflags glib-2.0`
      ar rcs libresize.a libresize.o

      $CC -Wall -c $src/server/plugin/plg_image_light/deps/src/libtranscode.c
      ar rcs libtranscode.a libtranscode.o
    '';

    installPhase = ''
      mkdir -p $out/lib
      mv libresize.a $out/lib/
      mv libtranscode.a $out/lib/
    '';
  };

  go = buildGoModule rec {
    pname = "filestash";
    inherit version;

    src = source;

    vendorSha256 = null;

    buildInputs = [
      glib tmp vips libraw
    ];

    nativeBuildInputs = [
      pkg-config
    ];

    preBuild = let
      path = (builtins.replaceStrings [ "/" ] [ "\\/" ] tmp.outPath);
    in ''
      sed -ie 's/-L.\/deps -l:libresize_linux_amd64.a/-L${path}\/lib -l:libresize.a -lvips/' /build/source/server/plugin/plg_image_light/lib_resize_linux_amd64.go
      sed -ie 's/-L.\/deps -l:libtranscode_linux_amd64.a/-L${path}\/lib -l:libtranscode.a -lraw/' /build/source/server/plugin/plg_image_light/lib_transcode_linux_amd64.go
    '';

    postInstall = ''
      cp $out/bin/server $out/bin/filestash
    '';

    excludedPackages = "\\(server/generator\\|server/plugin/plg_starter_http2\\|server/plugin/plg_starter_https\\)";
  };

in stdenv.mkDerivation {
    pname = "filestash";
    inherit version;

    phases = [ "InstallPhase" ];

    InstallPhase = ''
      mkdir -p $out/bin

      cp ${go}/bin/filestash $out/bin

      mkdir -p $out/data
      cp -r ${js}/data/public $out/data
    '';
}
