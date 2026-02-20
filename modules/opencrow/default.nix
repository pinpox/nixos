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

  himalayaVars = config.clan.core.vars.generators."opencrow-himalaya";

  # Himalaya config for the mail fetcher (IMAP only, no SMTP)
  himalayaFetcherConfig = pkgs.writeText "himalaya-fetcher-config.toml" ''
    [accounts."mailbox.org"]
    default = true
    display-name = "opencrow-fetcher"
    downloads-dir = "/tmp"

    backend.type = "imap"
    backend.host = "imap.mailbox.org"
    backend.port = 993
    backend.encryption.type = "tls"
    backend.auth.type = "password"
    backend.auth.command = "printenv EMAIL_PASSWORD"

    message.send.backend.type = "none"
  '';

  # Script that fetches starred/flagged emails to a directory
  onChangedMailScript = pkgs.writeShellScript "opencrow-fetch-starred" ''
    set -euo pipefail

    HIMALAYA="${lib.getExe pkgs.himalaya} -c ${himalayaFetcherConfig} -c ${himalayaVars.files."config".path}"

    MAIL_DIR="/var/lib/opencrow/mail-inbox"
    PIPE="/var/lib/opencrow/sessions/trigger.pipe"
    mkdir -p "$MAIL_DIR"

    # List flagged messages, get their IDs
    ids=$($HIMALAYA envelope list --folder INBOX --output json flag flagged | ${lib.getExe pkgs.jq} -r '.[].id')
    [ -z "$ids" ] && exit 0

    for id in $ids; do
      $HIMALAYA message read "$id" > "$MAIL_DIR/$(date +%s)-''${id}.txt"
      $HIMALAYA flag remove "$id" flagged
      $HIMALAYA flag add "$id" crow-processed
      $HIMALAYA message move Archive "$id"
    done

    # Notify the bot
    [ -p "$PIPE" ] && echo "New starred emails arrived. Read them from $MAIL_DIR" > "$PIPE"
  '';

  # goimapnotify configuration
  goimapnotifyConfig = pkgs.writeText "goimapnotify-config.yaml" (builtins.toJSON {
    configurations = [
      {
        host = "imap.mailbox.org";
        port = 993;
        tls = true;
        tlsOptions = {
          rejectUnauthorized = true;
        };
        usernameCMD = "${lib.getExe' pkgs.coreutils "printenv"} EMAIL_LOGIN";
        passwordCMD = "${lib.getExe' pkgs.coreutils "printenv"} EMAIL_PASSWORD";
        boxes = [
          {
            mailbox = "INBOX";
            onChangedMail = toString onChangedMailScript;
          }
        ];
      }
    ];
  });
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
    # Used by the goimapnotify fetcher service for IMAP credentials
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
        TOML
        cat > $out/envfile << ENV
        EMAIL_LOGIN='$(cat $prompts/EMAIL_LOGIN)'
        EMAIL_PASSWORD='$(cat $prompts/EMAIL_PASSWORD)'
        ENV
      '';
    };

    # Mail inbox directory for fetched emails
    systemd.tmpfiles.rules = [
      "d /var/lib/opencrow/mail-inbox 0750 root root -"
    ];

    # goimapnotify service: watches for starred emails and fetches them
    systemd.services.opencrow-goimapnotify = {
      description = "Watch IMAP for starred emails and fetch them for opencrow";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ coreutils bash himalaya jq ];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.goimapnotify} -conf ${goimapnotifyConfig}";
        EnvironmentFile = himalayaVars.files."envfile".path;
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };

    services.opencrow = {
      enable = true;
      environmentFiles = [
        config.clan.core.vars.generators."opencrow".files."envfile".path
        config.clan.core.vars.generators."opencrow-nextcloud".files."envfile".path
        config.clan.core.vars.generators."opencrow-nextcloud-work".files."envfile".path
        config.clan.core.vars.generators."opencrow-eversports".files."envfile".path
      ];
      extraPackages = with pkgs; [
        pi
        curl
        jq
      ];
      environment = {
        NEXTCLOUD_URL = "https://files.pablo.tools";
        NEXTCLOUD_USER = "pinpox";
        NEXTCLOUD_CALENDAR = "personal";

        WORK_NEXTCLOUD_URL = "https://nextcloud.clan.lol";
        WORK_NEXTCLOUD_USER = "pinpox";
        WORK_NEXTCLOUD_CALENDAR = "personal";

        OPENCROW_MATRIX_HOMESERVER = "https://matrix.org";
        OPENCROW_ALLOWED_USERS = "@pinpox:matrix.org";
        OPENCROW_HEARTBEAT_INTERVAL = "30m";
        OPENCROW_PI_SKILLS_DIR = "/var/lib/opencrow/skills";
      };
    };
  };
}
