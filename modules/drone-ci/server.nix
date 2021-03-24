{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.droneci;
in {

  options.pinpox.services.droneci = {
    enable = mkEnableOption "hello service";
    drone-admin = mkOption {
      type = types.str;
      default = "pinpox";
      example = "drone-admin-user";
      description = "DroneCI admin username";
    };

    drone-user = mkOption {
      type = types.str;
      default = "droneci";
      example = "drone-user";
      description = "User to run DroneCI as";
    };

    drone-host = mkOption {
      type = types.str;
      default = "drone.lounge.rocks";
      example = "droneci.example.com";
      description = "hostname of DroneCI server";
    };
  };

  config = mkIf cfg.enable {

    systemd.services.drone-server = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {

        BindReadOnlyPaths = [ "/etc/hosts:/etc/hosts" ];
        EnvironmentFile = [ "/var/src/secrets/drone-ci/envfile" ];
        Environment = [
          "PLUGIN_CUSTOM_DNS=8.8.8.8"
          "/etc/resolv.conf:/etc/resolv.conf"
          "GODEBUG=netdns=go"
          "DRONE_LOG_FILE=/var/lib/drone/log.txt"
          "DRONE_DATABASE_DATASOURCE=postgres:///${cfg.drone-user}?host=/run/postgresql"
          "DRONE_DATABASE_DRIVER=postgres"
          "DRONE_SERVER_PORT=:3030"
          "DRONE_USER_FILTER=lounge-rocks"
          "DRONE_USER_CREATE=username:${cfg.drone-admin},admin:true"
        ];
        ExecStart = "${pkgs.drone}/bin/drone-server";
        User = cfg.drone-user;
        Group = cfg.drone-user;
      };
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ cfg.drone-user ];
      ensureUsers = [{
        name = cfg.drone-user;
        ensurePermissions = { "DATABASE ${ cfg.drone-user}" = "ALL PRIVILEGES"; };
      }];
    };

    security.acme.acceptTerms = true;
    security.acme.email = "letsencrypt@pablo.tools";

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;
      clientMaxBodySize = "128m";
      recommendedProxySettings = true;
      commonHttpConfig = ''
        server_names_hash_bucket_size 128;
      '';

      virtualHosts = {
        "${cfg.drone-host}" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = { proxyPass = "http://127.0.0.1:3030"; };
        };
      };
    };

    nix.allowedUsers = [  cfg.drone-user];

    users.groups."${ cfg.drone-user}" = { };

    users.users."${ cfg.drone-user}" = {
      isSystemUser = true;
      createHome = true;
      group = "${ cfg.drone-user}";
    };
  };
}
