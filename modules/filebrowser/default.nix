{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.filebrowser;

filebrowser = pkgs.buildGoModule rec {

    pname = "filebrowser";
    version = "2.15.0";

    src = pkgs.fetchFromGitHub {
      owner = "filebrowser";
      repo = "filebrowser";
      rev = "v${version}";
      sha256 = "sha256-+XBi4rexNwjwEW7h8/6/5aZfnnfl7URp38rcDyn3CAc=";
    };

    vendorSha256 = "sha256-iq7/CUA1uLKk1W8YGAfcdXFpyT2ZBxUxuYOIeO7zVN8=";
    subPackages = [ "." ];

    meta = with lib; {
      description = "TODO";
      homepage = "TODO";
      # license = license;
      maintainers = with maintainers; [ pinpox ];
      platforms = platforms.linux;
    };
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
        # EnvironmentFile = [ "/var/src/secrets/filebrowser/envfile" ];
        # Environment = [
        #   "IRC_CHANNEL='#lounge-rocks'"
        # ];
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
