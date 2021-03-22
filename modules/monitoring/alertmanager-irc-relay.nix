{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.alertmanager-irc-relay;

  alertmanager-irc-relay = pkgs.buildGoModule rec {

    pname = "alertmanager-irc-relay";
    version = "0.3.0";

    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = "alertmanager-irc-relay";
      rev = "v${version}";
      sha256 = "sha256-SmyKk0vSXfHzRxOdbULD2Emju/VjDcXZZ7cgVbZxGIA=";
    };

    vendorSha256 = "sha256-aJVA9MJ9DK/dCo7aSB9OLfgKGN5L6Sw2k2aOR4J2LE4=";
    subPackages = [ "." ];

    meta = with lib; {
      description = "Send Prometheus Alerts to IRC using Webhooks";
      homepage = "https://github.com/google/alertmanager-irc-relay";
      license = licenses.asl20;
      maintainers = with maintainers; [ pinpox ];
      platforms = platforms.linux;
    };
  };


  relayConfig = pkgs.writeTextFile {
    name = "alertmanager-irc-relay-config";
    text = ''
      # Start the HTTP server receiving alerts from Prometheus Webhook binding to
      # this host/port.
      #
      http_host: localhost
      http_port: 9999

      # Connect to this IRC host/port.
      #
      # Note: SSL is enabled by default, use "irc_use_ssl: no" to disable.
      irc_host: chat.freenode.net
      irc_port: 6697
      # Optionally set the server password
      # irc_host_password: myserver_password

      # Use this IRC nickname.
      irc_nickname: $IRC_NICK
      # irc_nickname: status-bot-ptools
      # Password used to identify with NickServ
      irc_nickname_password: $IRC_PASS
      # Use this IRC real name
      irc_realname: Alertmanger IRC

      # Optionally pre-join certain channels.
      #
      # Note: If an alert is sent to a non # pre-joined channel the bot will join
      # that channel anyway before sending the message. Of course this cannot work
      # with password-protected channels.
      irc_channels:
        - name: "#lounge-rocks"

      # Define how IRC messages should be sent.
      #
      # Send only one message when webhook data is received.
      # Note: By default a message is sent for each alert in the webhook data.
      msg_once_per_alert_group: no
      #
      # Use PRIVMSG instead of NOTICE (default) to send messages.
      # Note: Sending PRIVMSG from bots is bad practice, do not enable this unless
      # necessary (e.g. unless NOTICEs would weaken your channel moderation policies)
      use_privmsg: no

      # Define how IRC messages should be formatted.
      #
      # The formatting is based on golang's text/template .
      msg_template: "Alert {{ .Labels.alertname }} on {{ .Labels.instance }} is {{ .Status }}"
      # Note: When sending only one message per alert group the default
      # msg_template is set to
      # "Alert {{ .GroupLabels.alertname }} for {{ .GroupLabels.job }} is {{ .Status }}"

      # Set the internal buffer size for alerts received but not yet sent to IRC.
      alert_buffer_size: 2048
    '';
  };

in {

  options.pinpox.services.alertmanager-irc-relay = {
    enable = mkEnableOption "Prometheus alert IRC relay bot";
  };

  config = mkIf cfg.enable {

    # User and group
    users.users.alertmanager-irc-relay = {
      isNormalUser = false;
      home = "/var/lib/alertmanager-irc-relay";
      description = "alertmanager-irc-relay system user";
      extraGroups = [ "alertmanager-irc-relay" ];
      # createHome = true;
    };

    users.groups.alertmanager-irc-relay= { name = "alertmanager-irc-relay"; };

    # Service
    systemd.services.alertmanager-irc-relay = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start the Alertmanager IRC relay";
      serviceConfig = {
        EnvironmentFile = [ "/var/src/secrets/alertmanager-irc-relay/envfile" ];
        # WorkingDirectory = "/var/lib/alertmanager-irc-relay";
        User = "alertmanager-irc-relay";
        ExecStart = "${alertmanager-irc-relay}/bin/alertmanager-irc-relay --config ${relayConfig}";
      };
    };
  };
}
