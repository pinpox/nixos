# { lib, stdenv, buildGoModule, fetchFromGitHub }:

# buildGoModule rec {
#   pname = "drone-runner-exec";
#   version = "2020-04-19";

#   src = fetchFromGitHub {
#     owner = "drone-runners";
#     repo = "drone-runner-exec";
#     rev = "c0a612ef2bdfdc6d261dfbbbb005c887a0c3668d";
#     sha256 = "sha256-0UIJwpC5Y2TQqyZf6C6neICYBZdLQBWAZ8/K1l6KVRs=";
#   };

#   vendorSha256 = "sha256-ypYuQKxRhRQGX1HtaWt6F6BD9vBpD8AJwx/4esLrJsw=";

#   meta = with lib; {
#     description =
#       "Drone pipeline runner that executes builds directly on the host machine";
#     homepage = "https://github.com/drone-runners/drone-runner-exec";
#     # https://polyformproject.org/licenses/small-business/1.0.0/
#     license = licenses.unfree;
#   };
# }

{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.droneci.runner-exec;
in {

  options.pinpox.services.droneci.runner-exec = {
    enable = mkEnableOption "DroneCI exec runner";
    # nodeTargets = mkOption {
    #   type = types.listOf types.str;
    #   default = [ "porree.wireguard:9100" ];
    #   example = [ "hostname.wireguard:9100" ];
    #   description = "Targets to monitor with the node-exporter";
    # };
  };

  config = mkIf cfg.enable {
    systemd.services.drone-runner-exec = {
      wantedBy = [ "multi-user.target" ];
      # might break deployment
      restartIfChanged = false;
      confinement.enable = true;
      confinement.packages =
        [ pkgs.git pkgs.gnutar pkgs.bash pkgs.nixUnstable pkgs.gzip ];
      path = [ pkgs.git pkgs.gnutar pkgs.bash pkgs.nixUnstable pkgs.gzip ];
      serviceConfig = {
        Environment = [
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
        EnvironmentFile = [ "/var/src/secrets/drone-ci/envfile" ];
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

  };
}
