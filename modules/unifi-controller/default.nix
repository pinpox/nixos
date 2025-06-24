{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.unifi-controller;
in
{

  options.pinpox.services.unifi-controller.enable = mkEnableOption "unifi controller (docker)";

  config = mkIf cfg.enable {

    users.users.unifi = {
      isSystemUser = true;
      description = "unifi user";
      extraGroups = [ "unifi" ];
      group = "unifi";
      createHome = true;
      home = "/var/lib/unifi";
    };

    users.groups.unifi.name = "unifi";

    # Access locally via:
    # https://birne:8443/manage/
    # Set inform via ssh:
    # set-inform http://birne:8080/inform
    virtualisation.oci-containers.containers = {
      unifi-contoller = {
        autoStart = true;
        image = "linuxserver/unifi-controller:version-5.6.42";

        environment = {
          "PUID" = toString config.users.users.unifi.uid;
          "PGID" = toString config.users.groups.unifi.gid;
          # "TZ" = "Etc/UTC";
          # "MEM_LIMIT" = "4096";
          # "MEM_STARTUP" = "4096";
        };

        ports = [
          "8080:8080"
          "8081:8081"
          "8443:8443"
          "8843:8843"
          "8880:8880"
        ];

        volumes = [ "${config.users.users.unifi.home}/config:/config" ];
      };
    };

    networking.firewall = {

      allowedUDPPorts = [
        3478 # Unifi UDP port used for STUN.
        10001 # Unifi UDP port used for device discovery.
      ];

      allowedTCPPorts = [
        8080 # Unifi port for UAP to inform controller.
        8880 # Unifi port for HTTP portal redirect, if guest portal is enabled.
        8843 # Unifi port for HTTPS portal redirect, ditto.
        6789 # Unifi port for UniFi mobile speed test.
      ];
    };

  };
}
