{
  config,
  lib,
  pinpox-utils,
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

    services.caddy = {
      enable = true;
      virtualHosts."${cfg.host}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.vaultwarden.config.ROCKET_PORT}
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
        SMTP_HOST = "mail.pinpox.com";
        SMTP_PORT = 465;
        SMTP_SECURITY = "force_tls";
        SMTP_FROM_NAME = "Vaultwarden";
      };

      environmentFile = [
        config.clan.core.vars.generators."vaultwarden".files."envfile".path
        config.clan.core.vars.generators."vaultwarden-smtp".files."env".path
      ];
    };

    clan.core.vars.generators."vaultwarden" = pinpox-utils.mkEnvGenerator [
      "YUBICO_CLIENT_ID"
      "YUBICO_SECRET_KEY"
      "ADMIN_TOKEN"
    ];

	# Deliberately not folded into the generator above so they can be re-rolled
	# separately.
    clan.core.vars.generators."vaultwarden-smtp" = {
      files."env" = { };
      prompts."address" = {
        type = "line";
        persist = true;
        description = "Mail address for vaultwarden";
      };
      prompts."app-password" = {
        type = "hidden";
        persist = true;
        description = "Mail password for vaultwarden";
      };
      script = ''
        addr="$(cat "$prompts"/address)"
        {
          printf 'SMTP_USERNAME=%s\n' "$addr"
          printf 'SMTP_FROM=%s\n' "$addr"
          printf 'SMTP_PASSWORD=%s\n' "$(cat "$prompts"/app-password)"
        } > "$out/env"
      '';
    };

    # Backup DB and persistent data (e.g. attachments)
    pinpox.services.restic-client.backup-paths-offsite = [
      "${config.services.vaultwarden.backupDir}"
      "/var/lib/bitwarden_rs"
    ];
  };
}
