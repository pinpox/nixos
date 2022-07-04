{ lib, pkgs, config, ... }:
with lib;
let cfg = config.pinpox.services.borg-server;
in
{

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

    services.nginx = {
      enable = true;
      recommendedOptimisation = true;
      clientMaxBodySize = "128m";
      recommendedProxySettings = true;

      virtualHosts = {
        "backup-reports" = {

          # Allow listing directory contents. Not strictly necessary, but easier
          # to debug
          extraConfig = "autoindex on;";

          # TODO create this directory if it does not exist
          root = "/var/www/backup-reports";

          # Only accessible over wireguard VPN
          listen = [{
            addr = "${config.pinpox.wg-client.clientIp}";
            port = 80;
          }];
        };
      };
    };

    # Create a repository for each of the hosts authorizing the provided keys
    services.borgbackup.repos = builtins.mapAttrs
      (name: value: {
        authorizedKeys = value.authorizedKeys;
        path = /mnt/backup/borg-nix + "/${name}";
      })
      cfg.repositories;

    lollypops.secrets.files = builtins.listToAttrs (map
      (hostname: {
        name = "borg-server/passphrases/${hostname}";
        value = { };
      })
      (builtins.attrNames cfg.repositories));

    systemd = {

      # Create a service for each hosts that exports the information of the
      # last archive of the corresponding repository
      services = builtins.listToAttrs (map
        (hostname: {
          name = "borgbackup-monitor-${hostname}";
          value = {
            serviceConfig.Type = "oneshot";
            serviceConfig.Environment =
              [ "BORG_RELOCATED_REPO_ACCESS_IS_OK=yes" ];
            script = ''
              export BORG_PASSCOMMAND='cat ${config.lollypops.secrets.files."borg-server/passphrases/${hostname}".path}'
              ${pkgs.borgbackup}/bin/borg info /mnt/backup/borg-nix/${hostname} --last=1 --json > /var/www/backup-reports/borg-${hostname}.json
            '';
          };
        })
        (builtins.attrNames cfg.repositories));

      # Create a timer for each host, that runs the service once every day
      timers = builtins.listToAttrs (map
        (hostname: {
          name = "borgbackup-monitor-${hostname}";
          value = {
            wantedBy = [ "timers.target" ];
            partOf = [ "borgbackup-monitor-${hostname}.service" ];
            timerConfig.OnCalendar = "daily";
          };
        })
        (builtins.attrNames cfg.repositories));
    };
  };
}
