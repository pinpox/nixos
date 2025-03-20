{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.vaultwarden;
in
{

  options.pinpox.services.vaultwarden = {
    enable = mkEnableOption "vaultwarden password manager";

    host = mkOption {
      type = types.str;
      default = "pass.pablo.tools";
      description = "Host serving vaultwarden";
      example = "pass.pablo.tools";
    };
  };

  config = mkIf cfg.enable {

    services.caddy =
      let

        # TODO Workaround for vaultwarden until the next release.
        # The current workaround will not be necessary/not work when this is released:
        # https://github.com/dani-garcia/vaultwarden/discussions/3996
        # Talked to @BlackDex on matrix.

        config_workfile = pkgs.writeTextFile {
          name = "config.json";
          text = ''
            {
              "environment": {
                "api": "https://pass.pablo.tools/api",
                "identity": "https://pass.pablo.tools/identity",
                "notifications": "https://pass.pablo.tools/notifications",
                "sso": "",
                "vault": "https://pass.pablo.tools"
              },
              "gitHash": "b707d616",
              "object": "config",
              "server": {
                "name": "Vaultwarden",
                "url": "https://github.com/dani-garcia/vaultwarden"
              },
              "version": "2023.9.0"
            }
          '';
        };
      in
      {
        enable = true;
        virtualHosts."${cfg.host}".extraConfig = ''
          handle /api/config/ {
            try_files {path} ${config_workfile}
            file_server
          }

          reverse_proxy 127.0.0.1:${builtins.toString config.services.vaultwarden.config.ROCKET_PORT}
        '';
      };

    systemd.services.backup-vaultwarden.serviceConfig.StateDirectory = "vaultwarden-backups";

    services.vaultwarden = {
      enable = true;
      dbBackend = "sqlite"; # Still in /var/lib/bitwarde_rs
      backupDir = "/var/lib/vaultwarden-backups"; # backup its persistent data
      config = {
        DOMAIN = "https://${cfg.host}";
        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = "true";
        ROCKET_PORT = 8222;
        EXPERIMENTAL_CLIENT_FEATURE_FLAGS = "ssh-key-vault-item,ssh-agent";
      };

      # The environment file contains secrets and is stored in pass
      # YUBICO_CLIENT_ID, YUBICO_SECRET_KEY, ADMIN_TOKEN
      environmentFile = "${config.lollypops.secrets.files."bitwarden_rs/envfile".path}";
    };

    lollypops.secrets.files."bitwarden_rs/envfile" = { };

    # Backup DB and persistent data (e.g. attachments)
    pinpox.services.restic-client.backup-paths-offsite = [
      "${config.services.vaultwarden.backupDir}"
      "/var/lib/bitwarden_rs"
    ];
  };
}
