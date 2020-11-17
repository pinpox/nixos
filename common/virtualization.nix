{ config, pkgs, lib, ... }: {

  environment.systemPackages = with pkgs; [
    qemu
  ];

  virtualisation.libvirtd = {
    enable = true;
    # Don't start the VMs on host boot
    onBoot = "ignore";
  };

  virtualisation.docker.enable = true;

  # Virtualbox stuff
  #virtualisation.virtualbox.guest.enable = true;
  # virtualisation.virtualbox.host.enable = true;
  # virtualisation.virtualbox.host.enableExtensionPack = true;
}
