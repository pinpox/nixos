{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
# Porree-side OpenCrow mail glue: the starred-mail watcher (goimapnotify +
# himalaya) that feeds the "claude" bot via its trigger pipe. The bot instances
# and their secrets live in the @pinpox/opencrow clan service; this module is
# the remaining mail integration, to be refactored/folded in later.
let
  cfg = config.pinpox.services.opencrow;

  # State dir of the "claude" opencrow instance (clan service instance name
  # "claude" → /var/lib/opencrow-claude). The mail watcher writes fetched mail
  # and trigger lines into this instance's state, which the clan service
  # bind-mounts into that bot's container.
  stateDir = "/var/lib/opencrow-claude";

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
  # NOTE: goimapnotify does not pass its environment to child scripts,
  # so we source the envfile explicitly to get EMAIL_PASSWORD/EMAIL_LOGIN.
  onChangedMailScript = pkgs.writeShellScript "opencrow-fetch-starred" ''
    set -euo pipefail

    set -a
    source ${himalayaVars.files."envfile".path}
    set +a

    HIMALAYA="${lib.getExe pkgs.himalaya} -c ${himalayaFetcherConfig} -c ${
      himalayaVars.files."config".path
    }"

    MAIL_DIR="${stateDir}/mail-inbox"
    PIPE="${stateDir}/sessions/trigger.pipe"
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
  goimapnotifyConfig = pkgs.writeText "goimapnotify-config.yaml" (
    builtins.toJSON {
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
    }
  );
in
{

  options.pinpox.services.opencrow.enable =
    mkEnableOption "opencrow starred-mail watcher (bot instances + their secrets are the @pinpox/opencrow clan service)";

  config = mkIf cfg.enable {

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

    # Mail inbox directory the watcher writes into. Lives inside the "claude"
    # instance's state dir (created world-writable so the host watcher writes
    # and the container's opencrow user reads).
    systemd.tmpfiles.rules = [
      "d ${stateDir}/mail-inbox 0777 root root -"
    ];

    # goimapnotify service: watches for starred emails and fetches them
    systemd.services.opencrow-goimapnotify = {
      description = "Watch IMAP for starred emails and fetch them for opencrow";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [
        coreutils
        bash
        himalaya
        jq
      ];
      serviceConfig = {
        ExecStart = "${lib.getExe pkgs.goimapnotify} -conf ${goimapnotifyConfig}";
        EnvironmentFile = himalayaVars.files."envfile".path;
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
