{
  opencrow,
  config,
  lib,
  pkgs,
  pinpox-utils,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.opencrow;

  env = config.services.opencrow.environment;

  # TODO no longer needed when this lands: https://github.com/pimalaya/himalaya/issues/632
  himalayaPublicConfig = pkgs.writeText "himalaya-config.toml" ''
    [accounts."mailbox.org"]
    default = true
    display-name = "${env.EMAIL_DISPLAY_NAME}"
    downloads-dir = "/var/lib/opencrow/downloads"

    backend.type = "imap"
    backend.host = "${env.EMAIL_IMAP_HOST}"
    backend.port = ${env.EMAIL_IMAP_PORT}
    backend.encryption.type = "tls"
    backend.auth.type = "password"
    backend.auth.command = "printenv EMAIL_PASSWORD"

    message.send.backend.type = "smtp"
    message.send.backend.host = "smtp.mailbox.org"
    message.send.backend.port = 465
    message.send.backend.encryption.type = "tls"
    message.send.backend.auth.type = "password"
    message.send.backend.auth.command = "printenv EMAIL_PASSWORD"
  '';
in
{

  imports = [ opencrow.nixosModules.default ];

  options.pinpox.services.opencrow.enable = mkEnableOption "opencrow Matrix bot";

  config = mkIf cfg.enable {

    # OpenCrow Matrix bot
    clan.core.vars.generators."opencrow" = pinpox-utils.mkEnvGenerator [
      "OPENCROW_MATRIX_ACCESS_TOKEN"
      "OPENCROW_MATRIX_USER_ID"
    ];

    # Nextcloud (personal)
    clan.core.vars.generators."opencrow-nextcloud" = pinpox-utils.mkEnvGenerator [
      "NEXTCLOUD_PASSWORD"
    ];

    # Nextcloud (work)
    clan.core.vars.generators."opencrow-nextcloud-work" = pinpox-utils.mkEnvGenerator [
      "WORK_NEXTCLOUD_PASSWORD"
    ];

    # Eversports
    clan.core.vars.generators."opencrow-eversports" = pinpox-utils.mkEnvGenerator [
      "EVERSPORTS_EMAIL"
      "EVERSPORTS_PASSWORD"
    ];

    # Himalaya email secrets (TOML config + env file for EMAIL_PASSWORD)
    # TODO no longer needed when this lands: https://github.com/pimalaya/himalaya/issues/632
    clan.core.vars.generators."opencrow-himalaya" = {
      files.config = { };
      files.envfile = { };
      runtimeInputs = [ pkgs.coreutils ];
      prompts.EMAIL_ADDRESS.persist = false;
      prompts.EMAIL_LOGIN.persist = false;
      prompts.EMAIL_PASSWORD.persist = false;
      script = ''
        mkdir -p $out
        cat > $out/config << TOML
        [accounts."mailbox.org"]
        email = "$(cat $prompts/EMAIL_ADDRESS)"
        backend.login = "$(cat $prompts/EMAIL_LOGIN)"
        message.send.backend.login = "$(cat $prompts/EMAIL_LOGIN)"
        TOML
        cat > $out/envfile << ENV
        EMAIL_LOGIN='$(cat $prompts/EMAIL_LOGIN)'
        EMAIL_PASSWORD='$(cat $prompts/EMAIL_PASSWORD)'
        ENV
      '';
    };

    services.opencrow = {
      enable = true;
      environmentFiles = [
        config.clan.core.vars.generators."opencrow".files."envfile".path
        config.clan.core.vars.generators."opencrow-nextcloud".files."envfile".path
        config.clan.core.vars.generators."opencrow-nextcloud-work".files."envfile".path
        config.clan.core.vars.generators."opencrow-himalaya".files."envfile".path
        config.clan.core.vars.generators."opencrow-eversports".files."envfile".path
      ];
      extraPackages = with pkgs; [
        pi
        curl
        jq
        himalaya
      ];
      extraBindMounts."/etc/himalaya/config.toml" = {
        hostPath = toString himalayaPublicConfig;
        isReadOnly = true;
      };
      extraBindMounts."/etc/himalaya/secrets.toml" = {
        hostPath = config.clan.core.vars.generators."opencrow-himalaya".files."config".path;
        isReadOnly = true;
      };
      environment = {
        HIMALAYA_CONFIG = "/etc/himalaya/config.toml /etc/himalaya/secrets.toml";

        NEXTCLOUD_URL = "https://files.pablo.tools";
        NEXTCLOUD_USER = "pinpox";
        NEXTCLOUD_CALENDAR = "personal";

        WORK_NEXTCLOUD_URL = "https://nextcloud.clan.lol";
        WORK_NEXTCLOUD_USER = "pinpox";
        WORK_NEXTCLOUD_CALENDAR = "personal";

        EMAIL_DISPLAY_NAME = "pinpox";
        EMAIL_IMAP_HOST = "imap.mailbox.org";
        EMAIL_IMAP_PORT = "993";

        OPENCROW_MATRIX_HOMESERVER = "https://matrix.org";
        OPENCROW_ALLOWED_USERS = "@pinpox:matrix.org";
        OPENCROW_HEARTBEAT_INTERVAL = "30m";
        OPENCROW_PI_SKILLS_DIR = "/var/lib/opencrow/skills";
      };
    };
  };
}
