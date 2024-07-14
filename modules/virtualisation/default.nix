{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.virtualisation;
in
{

  options.pinpox.virtualisation.docker = {
    enable = mkEnableOption "Docker virtualisation";
  };

  options.pinpox.virtualisation.virtualbox = {
    enable = mkEnableOption "VirtualBox virtualisation";
  };

  # TODO separate virtualbox and docker into separate enable options. For now
  # the virtualbox.enable option enables both while the docker.enable does
  # nothhing

  config = mkIf cfg.virtualbox.enable {

    users.users.pinpox.extraGroups = [ "docker" ];

    virtualisation.docker.enable = true;

    virtualisation.virtualbox.host.enable = true;
    # virtualisation.virtualbox.host.enableKvm = true;
    # virtualisation.virtualbox.host.addNetworkInterface = false;

    # virtualisation.virtualbox.host.enableExtensionPack = true;
    users.extraGroups.vboxusers.members = [ "pinpox" ];
  };
}
