{ config, pkgs, ... }: {

  services.telegraf = {
    enable = true;
    extraConfig.inputs = {

      file = {
        tag_keys = [ "archives_0_hostname" ];
        data_format = "json";
        json_string_fields = [
          "archives_0_comment"
          "archives_0_end"
          "archives_0_start"
          "archives_0_hostname"
          "archives_0_id"
          "archives_0_name"
          "archives_0_username"
        ];

        files = [
          "/var/lib/borg-monitor/ahorn.json"
          "/var/lib/borg-monitor/birne.json"
          "/var/lib/borg-monitor/kartoffel.json"
          "/var/lib/borg-monitor/kfbox.json"
          "/var/lib/borg-monitor/mega.json"
          "/var/lib/borg-monitor/porree.json"
        ];
      };
    };
  };

  systemd = {

    timers.monitor-borg-repos = {
      wantedBy = [ "timers.target" ];
      partOf = [ "monitor-borg-repos.service" ];
      timerConfig.OnCalendar = "daily";
    };

    services.monitor-borg-repos = {
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /var/lib/borg-monitor

        export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

        echo "Exporting info for ahorn"
        export BORG_PASSCOMMAND='cat /var/src/secrets/borg-server/passphrases/ahorn'
        ${pkgs.borgbackup}/bin/borg info --json --last 1 /mnt/backup/borg-nix/ahorn > /var/lib/borg-monitor/ahorn.json

        echo "Exporting info for birne"
        export BORG_PASSCOMMAND='cat /var/src/secrets/borg-server/passphrases/birne'
        ${pkgs.borgbackup}/bin/borg info --json --last 1 /mnt/backup/borg-nix/birne > /var/lib/borg-monitor/birne.json

        echo "Exporting info for kartoffel"
        export BORG_PASSCOMMAND='cat /var/src/secrets/borg-server/passphrases/kartoffel'
        ${pkgs.borgbackup}/bin/borg info --json --last 1 /mnt/backup/borg-nix/kartoffel > /var/lib/borg-monitor/kartoffel.json

        echo "Exporting info for kfbox"
        export BORG_PASSCOMMAND='cat /var/src/secrets/borg-server/passphrases/kfbox'
        ${pkgs.borgbackup}/bin/borg info --json --last 1 /mnt/backup/borg-nix/kfbox > /var/lib/borg-monitor/kfbox.json

        echo "Exporting info for mega"
        export BORG_PASSCOMMAND='cat /var/src/secrets/borg-server/passphrases/mega'
        ${pkgs.borgbackup}/bin/borg info --json --last 1 /mnt/backup/borg-nix/mega > /var/lib/borg-monitor/mega.json

        echo "Exporting info for porree"
        export BORG_PASSCOMMAND='cat /var/src/secrets/borg-server/passphrases/porree'
        ${pkgs.borgbackup}/bin/borg info --json --last 1 /mnt/backup/borg-nix/porree > /var/lib/borg-monitor/porree.json
      '';
    };
  };

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
