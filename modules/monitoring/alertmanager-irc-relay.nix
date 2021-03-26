{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.alertmanager-irc-relay;

  alertmanager-irc-relay = pkgs.buildGoModule rec {

    pname = "alertmanager-irc-relay";
    version = "0.3.0";

    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "alertmanager-irc-relay";
      rev = "v${version}";
      sha256 = "sha256-SmyKk0vSXfHzRxOdbULD2Emju/VjDcXZZ7cgVbZxGIA=";
    };

    vendorSha256 = "sha256-aJVA9MJ9DK/dCo7aSB9OLfgKGN5L6Sw2k2aOR4J2LE4=";
    subPackages = [ "." ];

    meta = with lib; {
      description = "Send Prometheus Alerts to IRC using Webhooks";
      homepage = "https://github.com/google/alertmanager-irc-relay";
      license = licenses.asl20;
      maintainers = with maintainers; [ pinpox ];
      platforms = platforms.linux;
    };
  };


  relayConfig = pkgs.writeTextFile {
    name = "alertmanager-irc-relay-config";
    text = ''
    '';
  };

in {

  options.pinpox.services.alertmanager-irc-relay = {
    enable = mkEnableOption "Prometheus alert IRC relay bot";
  };

  config = mkIf cfg.enable {

    # User and group
    users.users.alertmanager-irc-relay = {
      isNormalUser = false;
      home = "/var/lib/alertmanager-irc-relay";
      description = "alertmanager-irc-relay system user";
      extraGroups = [ "alertmanager-irc-relay" ];
      # createHome = true;
    };

    users.groups.alertmanager-irc-relay= { name = "alertmanager-irc-relay"; };

    # Service
    systemd.services.alertmanager-irc-relay = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start the Alertmanager IRC relay";
      serviceConfig = {
        PermissionsStartOnly = true;
        EnvironmentFile = [ "/var/src/secrets/alertmanager-irc-relay/envfile" ];
        User = "alertmanager-irc-relay";
        ExecStartPre=''
          /run/current-system/sw/bin/install /var/src/secrets/alertmanager-irc-relay/config.yaml \
          /var/lib/alertmanager-irc-relay/config.yaml \
          --group=alertmanager-irc-relay --owner=alertmanager-irc-relay \
          --mode=600 -T -D'';
        ExecStart = "${alertmanager-irc-relay}/bin/alertmanager-irc-relay --config ${relayConfig}";
      };
    };
  };
}
