{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.monitoring-server.alertmanager-irc-relay;

  am-irc-conf = {
    # listening host/port.
    http_host = "localhost";
    http_port = 8667;

    # Connect to this IRC host/port.
    irc_host = "irc.hackint.org";
    irc_port = 6697;
    # irc_host_password = "myserver_password";
    irc_nickname = "alertus-maximus";
    irc_nickname_password = "mynickserv_key";
    irc_realname = "myrealname";

    irc_channels = [{ name = "#lounge-rocks-log"; }];

    msg_once_per_alert_group = false;
    # Use PRIVMSG instead of NOTICE (default) to send messages.
    use_privmsg = true;

    # Define how IRC messages should be formatted.
    msg_template =
      "⚠ ⚠ ⚠ [{{.Labels.instance}}] - {{ .Labels.alertname }} is {{.Status}} ⚠ ⚠ ⚠ {{.Annotations.description}} (@pinpox act accordingly)";
    # Note: When sending only one message per alert group the default
    # msg_template is set to
    # "Alert {{ .GroupLabels.alertname }} for {{ .GroupLabels.job }} is {{ .Status }}"

    # Set the internal buffer size for alerts received but not yet sent to IRC.
    alert_buffer_size = 2048;

    # Patterns used to guess whether NickServ is asking us to IDENTIFY
    # Note: If you need to change this because the bot is not catching a request
    # from a rather common NickServ, please consider sending a PR to update the
    # default config instead.
    # nickserv_identify_patterns = [
    #   "identify via /msg NickServ identify <password>"
    #   "type /msg NickServ IDENTIFY password"
    #   "authenticate yourself to services with the IDENTIFY command"
    # ];
  };

  confPath = pkgs.writeText "config.yml" (builtins.toJSON am-irc-conf);
in
{

  options.pinpox.services.monitoring-server.alertmanager-irc-relay = {
    enable = mkEnableOption "alertmanager-irc-relay";
  };

  config = mkIf cfg.enable {

    # User and group
    users.groups."alertmanager-irc-relay" = { };
    users.users."alertmanager-irc-relay" = {
      isSystemUser = true;
      # createHome = true;
      group = "alertmanager-irc-relay";
    };

    # Service
    systemd.services.alertmanager-irc-relay = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {

        # Environment = [ ];

        ExecStart =
          "${pkgs.alertmanager-irc-relay}/bin/alertmanager-irc-relay --config ${confPath}";
        User = config.users.users.alertmanager-irc-relay.name;
        Group = config.users.users.alertmanager-irc-relay.name;
      };
    };
  };
}
