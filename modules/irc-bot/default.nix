{ lib, pkgs, config, ... }:
with lib;
let
  cfg = config.pinpox.services.go-karma-bot;

  go-karma-bot = pkgs.buildGoModule rec {

    pname = "go-karma-bot";
    version = "1.1";

    src = pkgs.fetchFromGitHub {
      owner = "pinpox";
      repo = "go-karma-bot";
      rev = "v${version}";
      sha256 = "sha256-L/mL37XMERbn4rhJMq0iFIGRYo2mHWIR4cSgTty0I1U=";
    };

    vendorSha256 = "sha256-si9G6t7SULor9GDxl548WKIeBe4Ik21f+lgNN+9bwzg=";
    subPackages = [ "." ];

    meta = with lib; {
      description = "IRC Bot that tracks karma of things";
      homepage = "https://github.com/pinpox/go-karma-bot";
      license = licenses.gpl3;
      maintainers = with maintainers; [ pinpox ];
      platforms = platforms.linux;
    };
  };

in {

  options.pinpox.services.go-karma-bot = {
    enable = mkEnableOption "the irc bot.";
  };

  config = mkIf cfg.enable {

    # User and group
    users.users.go-karma-bot = {
      isNormalUser = false;
      home = "/var/lib/go-karma-bot";
      description = "go-karma-bot system user";
      extraGroups = [ "go-karma-bot" ];
      createHome = true;
    };

    users.groups.go-karma-bot = { name = "go-karma-bot"; };

    # Service
    systemd.services.go-karma-bot = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start the IRC karma-bot";
      serviceConfig = {
        EnvironmentFile = [ "/var/src/secrets/go-karma-bot/envfile" ];
        WorkingDirectory = "/var/lib/go-karma-bot";
        User = "go-karma-bot";
        ExecStart = "${go-karma-bot}/bin/go-karma-bot";
      };
    };
  };
}
