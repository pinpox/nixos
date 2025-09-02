{
  config,
  pkgs,
  lib,
  ...
}:

let
  pinpox-utils = import ../../utils { inherit pkgs lib; };
in
{
  pinpox.virtualisation.docker.enable = true;

  clan.core.vars.generators."abiotic-docker" = pinpox-utils.mkEnvGenerator [
    "ServerPassword"
  ];

  virtualisation.oci-containers.containers = {
    abiotic-factor = {
      autoStart = true;
      image = "ghcr.io/pleut/abiotic-factor-linux-docker:latest";

      environmentFiles = [ config.clan.core.vars.generators."abiotic-docker".files.envfile.path ];

      environment = {
        "MaxServerPlayers" = "6";
        "Port" = "7777";
        "QueryPort" = "27015";
        "SteamServerName" = "pinpox server";
        "UsePerfThreads" = "true";
        "NoAsyncLoadingThread" = "true";
        "WorldSaveName" = "Cascade";
        # "AutoUpdate" = true;
        # "AdditionalArgs" = "-SandboxIniPath=Config/WindowsServer/Server1Sandbox.ini";
      };

      ports = [
        "0.0.0.0:7777:7777/udp"
        "0.0.0.0:27015:27015/udp"
      ];

      volumes = [
        "/var/lib/abiotic/gamefiles:/server"
        "/var/lib/abiotic/data:/server/AbioticFactor/Saved"
      ];
    };
  };

  networking.firewall.allowedUDPPorts = [
    7777
    27015
  ];
}
