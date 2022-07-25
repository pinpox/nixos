{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.droneci.runner-docker;
in
{

  options.pinpox.services.droneci.runner-docker = {
    enable = mkEnableOption "DroneCI docker runner";
  };

  config = mkIf cfg.enable {

    virtualisation.oci-containers.containers = {
      drone-runner = {
        autoStart = true;
        image = "drone/drone-runner-docker:1";

        environment = {
          DRONE_RPC_PROTO = "https";
          DRONE_RPC_HOST = "drone.lounge.rocks";
          DRONE_RUNNER_CAPACITY = "8";
          DRONE_RUNNER_NAME = "drone-runner";
        };

        extraOptions =
          [ "--network=host" "--env-file=${config.lollypops.secrets.files."drone-ci/envfile".path}" ];

        ports = [ "3000:3000" ];
        volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
      };
    };

    networking = {
      extraHosts = ''
        127.0.0.1 drone.lounge.rocks
      '';
    };
  };
}
