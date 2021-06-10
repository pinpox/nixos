{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.filebrowser;

  filebrowser = pkgs.stdenv.mkDerivation rec {
    name = "filebrowser";
    version = "v2.15.0";
    src = pkgs.fetchurl {

      # TODO use flake inputs
      url =
        "https://github.com/filebrowser/filebrowser/releases/download/${version}/linux-amd64-filebrowser.tar.gz";
      sha256 = "0ryh35n0z241sfhcnwac0qa1vpxdn8bnlpw4kqhz686mvnr1p1x4";
    };

    # Work around the "unpacker appears to have produced no directories"
    # case that happens when the archive doesn't have a subdirectory.
    setSourceRoot = "sourceRoot=`pwd`";

    installPhase = ''
      mkdir -p $out/bin
      cp filebrowser "$out"/bin/filebrowser
    '';
  };

in {

  options.pinpox.services.filebrowser = {
    enable = mkEnableOption "filebrowser webUI";
  };

  config = mkIf cfg.enable {

    # User and group
    users.users.filebrowser = {
      isSystemUser = true;
      home = "/var/lib/filebrowser";
      description = "filebrowser system user";
      extraGroups = [ "filebrowser" ];
      createHome = true;
    };

    users.groups.filebrowser = { name = "filebrowser"; };

    # Service
    systemd.services.filebrowser = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start filebrowser";
      serviceConfig = {
        EnvironmentFile = [ "/var/src/secrets/filebrowser/envfile" ];
        # Environment = [ ];
        WorkingDirectory = "/var/lib/filebrowser";
        User = "filebrowser";
        ExecStart = "${filebrowser}/bin/filebrowser";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # TODO Reverse proxy
  };
}
