{ pkgs, config, ... }: {
  virtualisation.oci-containers.containers = {
    drone-runner = {
      autoStart = true;
      image = "drone/drone-runner-docker:1";

      environment = {
        DRONE_RPC_PROTO = "https";
        DRONE_RPC_HOST = "drone.lounge.rocks";
        DRONE_RUNNER_CAPACITY = "2";
        DRONE_RUNNER_NAME = "\${HOSTNAME}";
        DRONE_RPC_SECRET="$(cat /var/src/secrets/drone-ci/envfile)";
      };

      ports = [ "3000:3000" ];
      volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    };
  };
}
