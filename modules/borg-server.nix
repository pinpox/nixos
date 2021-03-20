{ config, pkgs, ... }: {

  # Repositories for all hosts
  services.borgbackup.repos.kartoffel = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHmA67Wm0zAJ+SK1/hhoTO4Zjwe2FyE/6DlyC4JD5S0X borg@kartoffel"
    ];
    path = /mnt/backup/borg-nix/kartoffel;
  };

  services.borgbackup.repos.porree = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEi3WWUu3LXSckiOl1m+4Gjeb71ge7JV6IvBu9Y+R7uZ borg@porree"
    ];
    path = /mnt/backup/borg-nix/porree;
  };

  services.borgbackup.repos.ahorn = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINMiQyd921cRNjN4+uGlHS0UjKV3iPTVOWBypvzJVJ6a borg@ahorn"
    ];
    path = /mnt/backup/borg-nix/ahorn;
  };

  services.borgbackup.repos.birne = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwlv5kttrOxSF9EWffxzj8SDEQvFnJbq139HEQsTLVV borg@birne"
    ];
    path = /mnt/backup/borg-nix/birne;
  };

  services.borgbackup.repos.kfbox = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6bgC5b0zWJTzI58zWGRdFtTvnS6EGeV9NKymVXf4Ht borg@kfbox"
    ];
    path = /mnt/backup/borg-nix/kfbox;
  };

  services.borgbackup.repos.mega = {
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJW3f7nGeEDJIvu7LyLz/bWswPq9gR7AnC9vtiCmdG7C borg@mega"
    ];
    path = /mnt/backup/borg-nix/mega;
  };
}
