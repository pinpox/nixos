{ lib, pkgs, config, ... }:
with lib;

let cfg = config.pinpox.metrics.github;

in {

  options.pinpox.metrics.github = {

    enable = mkEnableOption "prometheus github-exporter metrics collection";

    # envfile = mkOption {
    #   type = types.str;
    #   default = "/var/src/secrets/github-exporter/envfile";
    #   example = "/path/to/envfile";
    #   description = "EnvironmentFile for github-exporter";
    # };
  };

  config = mkIf cfg.enable {

    # User and group
    users.groups."github-exporter" = { };
    users.users."github-exporter" = {
      isSystemUser = true;
      group = "github-exporter";
    };

    users.users.github-exporter = { extraGroups = [ "keys" ]; };
    krops.secrets.files = {

      github-exporter-token = {
        owner = "github-exporter";
        source-path = "/var/src/secrets/github-exporter/github-token";
      };
    };

    # Service
    systemd.services.github-exporter = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        # EnvironmentFile = [ cfg.envfile ];
        Environment = [

          # If supplied instead of GITHUB_TOKEN, enables the user to supply a path to
          # a file containing a github authentication token that allows the API to be
          # queried more often. Optional, but recommended.
          "GITHUB_TOKEN_FILE=/run/keys/github-exporter-token"

          #If supplied, the exporter will enumerate all repositories for that organization. Expected in the format "org1, org2".
          # "ORGS="

          #If supplied, The repos you wish to monitor, expected in the format "user/repo1, user/repo2". Can be across different Github users/orgs.
          "REPOS=pinpox/wallpaper-generator"

          #If supplied, the exporter will enumerate all repositories for that users. Expected in the format "user1, user2".
          # "USERS="

          # The port you wish to run the container on, the Dockerfile defaults this to 9171
          # "LISTEN_PORT="

          # the metrics URL path you wish to use, defaults to /metrics
          # "METRICS_PATH="

          # The level of logging the exporter will run with, defaults to debug
          # "LOG_LEVEL="

          # If supplied, enables the user to supply a github authentication token that allows the API to be queried more often. Optional, but recommended.
          # GITHUB_TOKEN

          # Github API URL, shouldn't need to change this. Defaults to https://api.github.com
          # API_URL
        ];
        ExecStart = " ${pkgs.github-exporter}/bin/github-exporter";
        User = config.users.users.github-exporter.name;
        Group = config.users.users.github-exporter.name;
      };
    };

    # Open firewall ports on the wireguard interface
    # networking.firewall.interfaces.wg0.allowedTCPPorts =
    #   lib.optional cfg.blackbox.enable 9115
    #   ++ lib.optional cfg.node.enable 9100;
  };
}
