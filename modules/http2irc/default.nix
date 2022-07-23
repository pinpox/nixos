{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.monitoring-server.http-irc;

  http2irc = pkgs.buildGoModule rec {

    pname = "http2irc";
    version = "1.0";

    # TODO use flake inputs
    src = pkgs.fetchFromGitHub {
      owner = "pinpox";
      repo = "http2irc";
      rev = "v${version}";
      sha256 = "sha256-5aHQ3Y0Md0qrJlFju8Nx6S5Ul+SVZOtFrcx90oiVvWo=";
    };

    vendorSha256 = "sha256-k45e6RSIl3AQdOFQysIwJP9nlYsSFeaUznVIXfbYwLA=";
    subPackages = [ "." ];

    meta = with lib; {
      description = "Webhook reciever to annouce in IRC channels";
      homepage = "https://github.com/pinpox/http2irc";
      license = licenses.gpl3;
      maintainers = with maintainers; [ pinpox ];
      platforms = platforms.linux;
    };
  };

  templateFile = pkgs.writeTextFile {
    name = "template.mustache";
    text = concatStrings [
      "{{#drone}}{{drone}}{{/drone}}"
      "{{#plain}}{{plain}}{{/plain}}"
    ];
  };
  # port-loki = 3100;
in
{

  options.pinpox.services.monitoring-server.http-irc = {
    enable = mkEnableOption "http2irc webhook relay";
  };

  config = mkIf cfg.enable {

    # User and group
    users.users.http2irc = {
      isSystemUser = true;
      home = "/var/lib/http2irc";
      description = "http2irc system user";
      group = "http2irc";
      createHome = true;
    };

    users.groups.http2irc = { name = "http2irc"; };

    lollypops.secrets.files."http2irc/envfile" = { };

    # Service
    systemd.services.http2irc = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start http2irc";
      serviceConfig = {
        EnvironmentFile = [ config.lollypops.secrets.files."http2irc/envfile".path ];
        Environment = [
          "IRC_TEMPLATE='${templateFile}'"
          "IRC_CHANNEL='#lounge-rocks'"
          "IRC_DEBUG='false'"
          "IRC_LISTEN=localhost:8989"
          "IRC_NOTICE='true'"
          "IRC_SERVER='irc.freenode.net:7000'"
        ];
        WorkingDirectory = "/var/lib/http2irc";
        User = "http2irc";
        ExecStart = "${http2irc}/bin/http2irc";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };

    # Reverse proxy

  };
}
