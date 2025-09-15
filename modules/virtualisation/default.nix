{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.virtualisation;
in
{

  options.pinpox.virtualisation = {
    docker.enable = mkEnableOption "Docker virtualisation";
    virtualbox.enable = mkEnableOption "VirtualBox virtualisation";
    virt-manager.enable = mkEnableOption "Virt-Manager virtualisation";
  };

  config = mkMerge [
    (mkIf cfg.docker.enable {
      users.users.pinpox.extraGroups = [ "docker" ];
      virtualisation.docker.enable = true;
    })

    (mkIf cfg.virt-manager.enable {
      boot.kernelModules = [ "kvm-amd" ];
      virtualisation.libvirtd.enable = true;
      programs.virt-manager.enable = true;
    })

    (mkIf cfg.virtualbox.enable {
      users.extraGroups.vboxusers.members = [ "pinpox" ];
      virtualisation.virtualbox.host.enable = true;
      # virtualisation.virtualbox.host.enableKvm = true;
      # virtualisation.virtualbox.host.addNetworkInterface = false;
      # virtualisation.virtualbox.host.enableExtensionPack = true;
    })
  ];
}
