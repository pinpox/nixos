{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.droneci.runner-exec;
in
{

  options.pinpox.services.droneci.runner-exec = {
    enable = mkEnableOption "DroneCI exec runner";
  };

  config = mkIf cfg.enable {

    lollypops.secrets.files."drone-ci/envfile" = { };

    systemd.services.drone-runner-exec = {
      wantedBy = [ "multi-user.target" ];
      # might break deployment
      restartIfChanged = false;
      confinement.enable = true;
      confinement.packages =
        [ pkgs.git pkgs.gnutar pkgs.bash pkgs.nixUnstable pkgs.gzip ];
      path = [
        pkgs.bash
        pkgs.bind
        pkgs.dnsutils
        pkgs.git
        pkgs.gnutar
        pkgs.gzip
        pkgs.nixUnstable
        pkgs.openssh
      ];
      serviceConfig = {
        Environment = [
          "DRONE_RUNNER_CAPACITY=1"
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
          "/etc/hosts:/etc/hosts"
          "/etc/group:/etc/group"
          "/nix/var/nix/profiles/system/etc/nix:/etc/nix"
          "${
            config.environment.etc."ssl/certs/ca-certificates.crt".source
          }:/etc/ssl/certs/ca-certificates.crt"
          "${
            config.environment.etc."ssh/ssh_known_hosts".source
          }:/etc/ssh/ssh_known_hosts"
          # "${
          #   builtins.toFile "ssh_config" ''
          #     Host eve.thalheim.io
          #       ForwardAgent yes
          #   ''
          # }:/etc/ssh/ssh_config"
          "/etc/machine-id"
          # channels are dynamic paths in the nix store, therefore we need to bind mount the whole thing
          "/nix/"
        ];
        EnvironmentFile = [ config.lollypops.secrets.files."drone-ci/envfile".path ];
        ExecStart = "${pkgs.drone-runner-exec}/bin/drone-runner-exec";
        User = "drone-runner-exec";
        Group = "drone-runner-exec";
      };
    };

    users.users.drone-runner-exec = {
      isSystemUser = true;
      group = "drone-runner-exec";
    };
    users.groups.drone-runner-exec = { };

    nix.settings.allowed-users = [ "drone-runner-exec" ];

  };
}
