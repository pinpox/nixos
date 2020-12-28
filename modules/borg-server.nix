{ config, pkgs, ... }: {

  services.borgbackup.repos.kartoffel = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHmA67Wm0zAJ+SK1/hhoTO4Zjwe2FyE/6DlyC4JD5S0X borg@kartoffel"
    ];
    path = /mnt/backup/borg-nix/kartoffel;
  };
}
