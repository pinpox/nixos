{ config, lib, ... }:
with lib;
let cfg = config.pinpox.services.vaultwarden;

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

    services.caddy = {
      enable = true;
      virtualHosts."${cfg.host}".extraConfig =
        "reverse_proxy 127.0.0.1:${config.services.vaultwarden.config.ROCKET_PORT}";
    };

    services.vaultwarden = {
      enable = true;
      dbBackend = "sqlite"; # Still in /var/lib/bitwarde_rs
      backupDir = "/var/backup/vaultwarden"; # backup its persistent data
      config = {
        DOMAIN = "https://${cfg.host}";
        SIGNUPS_ALLOWED = false;
        INVITATIONS_ALLOWED = "true";
        ROCKET_PORT = 8222;
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
