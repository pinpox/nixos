{ pkgs, config, ... }:

let
  drone-admin = "pinpox";
  drone-host = "drone.lounge.rocks";

  drone_user = "droneci";
in {
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
        "DRONE_DATABASE_DATASOURCE=postgres:///${drone_user}?host=/run/postgresql"
        "DRONE_DATABASE_DRIVER=postgres"
        "DRONE_SERVER_PORT=:3030"
        "DRONE_USER_FILTER=lounge-rocks"
        "DRONE_USER_CREATE=username:${drone-admin},admin:true"
      ];
      ExecStart = "${pkgs.drone}/bin/drone-server";
      User = drone_user;
      Group = drone_user;
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ drone_user ];
    ensureUsers = [{
      name = drone_user;
      ensurePermissions = { "DATABASE ${drone_user}" = "ALL PRIVILEGES"; };
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
      "${drone-host}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = { proxyPass = "http://127.0.0.1:3030"; };
      };
    };
  };

  nix.allowedUsers = [ drone_user ];

  users.groups."${drone_user}" = { };

  users.users."${drone_user}" = {
    isSystemUser = true;
    createHome = true;
    group = "${drone_user}";
  };
}
