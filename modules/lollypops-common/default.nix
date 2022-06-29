{ config, lollypops, ... }:
{

  imports = [ lollypops.nixosModules.lollypops ];

  lollypops.secrets = {
    default-dir = "/var/src/lollypops-secrets";
    cmd-name-prefix = "nixos-secrets/${config.networking.hostName}/";
  };
}
