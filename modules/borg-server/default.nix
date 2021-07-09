{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.borg-server;
in {

  options.pinpox.services.borg-server = {

    enable = mkEnableOption "borg-server setup";

    # Hosts to backup with keys
    repositories = mkOption {
      type = with types; attrsOf (types.attrsOf (types.listOf types.string));
      default = { };
      example = {
        myHostname.authorizedKeys = [
          "ssh-ed25519 AAAAXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/XXXXXXXXXXXXXXXXXXXXXXX borg@myHostname"
        ];
      };

      description = ''
        Attribute set of the hosts to backup, with the respective public keys
        authorized for the repository.
      '';
    };
  };

  config = mkIf cfg.enable {

    # Create a repository for each of the hosts authorizing the provided keys
    services.borgbackup.repos = builtins.mapAttrs (name: value: {
      authorizedKeys = value.authorizedKeys;
      path = /mnt/backup/borg-nix + "/${name}";
    }) cfg.repositories;

    systemd = {

      # Create a service for each hosts that exports the information of the
      # last archive of the corresponding repository
      services = builtins.listToAttrs (map (hostname: {
        name = "borgbackup-monitor-${hostname}";
        value = {
          serviceConfig.Type = "oneshot";
          script = ''
            export BORG_PASSCOMMAND='cat /var/src/secrets/borg-server/passphrases/${hostname}'
            ${pkgs.borgbackup}/bin/borg info /mnt/backup/borg-nix/${hostname} --last=1 --json > /tmp/borg-${hostname}.json
          '';
        };
      }) (builtins.attrNames cfg.repositories));

      # Create a timer for each host, that runs the service once every day
      timers = builtins.listToAttrs (map (hostname: {
        name = "borgbackup-monitor-${hostname}";
        value = {
          wantedBy = [ "timers.target" ];
          partOf = [ "borgbackup-monitor-${hostname}.service" ];
          timerConfig.OnCalendar = "daily";
        };
      }) (builtins.attrNames cfg.repositories));
    };
  };
}
