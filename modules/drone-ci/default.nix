{ pkgs, config, ... }:

let
  drone-admin = "pinpox";
  drone-host = "drone.pablo.tools";
  drone-runner-exec = pkgs.callPackage ./drone-runner-exec.nix {};

  # droneserver = config.users.users.droneserver.name;
  droneserver = "droneci";
in
{
  systemd.services.drone-server = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {

      BindReadOnlyPaths = [
        "/etc/hosts:/etc/hosts"
      ];
      EnvironmentFile = [
        "/var/src/secrets/drone-ci/envfile"
      ];
      Environment = [
"PLUGIN_CUSTOM_DNS=8.8.8.8"
        "/etc/resolv.conf:/etc/resolv.conf"
"GODEBUG=netdns=go"
"DRONE_LOG_FILE=/var/lib/drone/log.txt"
        "DRONE_DATABASE_DATASOURCE=postgres:///${droneserver}?host=/run/postgresql"
        "DRONE_DATABASE_DRIVER=postgres"
        "DRONE_SERVER_PORT=:3030"
        "DRONE_USER_CREATE=username:${drone-admin},admin:true"
      ];
      ExecStart = "${pkgs.drone}/bin/drone-server";
      User = droneserver;
      Group = droneserver;
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ droneserver ];
    ensureUsers = [{
      name = droneserver;
      ensurePermissions = {
        "DATABASE ${droneserver}" = "ALL PRIVILEGES";
      };
    }];
  };

  services.nginx.virtualHosts."${drone-host}" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = { proxyPass = "http://127.0.0.1:3030"; };
  };

  systemd.services.drone-runner-exec = {
    wantedBy = [ "multi-user.target" ];
    # might break deployment
    restartIfChanged = false;
    confinement.enable = true;
    confinement.packages = [
      pkgs.git
      pkgs.gnutar
      pkgs.bash
      pkgs.nixUnstable
      pkgs.gzip
      pkgs.bind
      pkgs.dnsutils
      pkgs.openssh
    ];
    path = [
      pkgs.git
      pkgs.gnutar
      pkgs.bash
      pkgs.nixUnstable
      pkgs.gzip
      pkgs.bind
      pkgs.dnsutils
      pkgs.openssh
    ];
    serviceConfig = {
      Environment = [
        "PLUGIN_CUSTOM_DNS=8.8.8.8"
"DRONE_LOG_FILE=/var/lib/drone/log.txt"
"GODEBUG=netdns=go"
        "DRONE_RUNNER_CAPACITY=10"
        "CLIENT_DRONE_RPC_HOST=127.0.0.1:3030"
        "NIX_REMOTE=daemon"
        "PAGER=cat"
      ];
      BindPaths = [
        "/nix/var/nix/daemon-socket/socket"
        "/run/nscd/socket"
        "/var/lib/drone"
      ];
      BindReadOnlyPaths = [
        "/etc/passwd:/etc/passwd"
        "/etc/resolv.conf:/etc/resolv.conf"
        "/etc/group:/etc/group"
        "/nix/var/nix/profiles/system/etc/nix:/etc/nix"
        "/etc/hosts:/etc/hosts"
        "${config.environment.etc."ssl/certs/ca-certificates.crt".source}:/etc/ssl/certs/ca-certificates.crt"
        # "${config.environment.etc."ssh/ssh_known_hosts".source}:/etc/ssh/ssh_known_hosts"
        # "${builtins.toFile "ssh_config" ''
        #   Host eve.thalheim.io
        #     ForwardAgent yes
        # ''}:/etc/ssh/ssh_config"
        "/etc/machine-id"
        # channels are dynamic paths in the nix store, therefore we need to bind mount the whole thing
        "/nix/"
      ];
        # TODO
      EnvironmentFile = [ "/var/src/secrets/drone-ci/envfile" ];
      ExecStart = "${drone-runner-exec}/bin/drone-runner-exec";

      # TODO ExecStartPre fails, find a way to create this directory, for now it has to be created manually
      # ExecStartPre = "/run/current-system/sw/bin/mkdir -p /var/lib/drone";
      User = "drone-runner-exec";
      Group = "drone-runner-exec";
    };
  };
  users.users.drone-runner-exec = {
    isSystemUser = true;
    group = "drone-runner-exec";
  };
  users.groups.drone-runner-exec = { };

  users.users."${droneserver}" = {
    isSystemUser = true;
    createHome = true;
    group = droneserver;
  };
  users.groups."${droneserver}" = { };

  # sops.secrets.drone = { };
}
