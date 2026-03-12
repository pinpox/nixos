{
  config,
  lib,
  mc3000,
  punchcard,
  pinpox-utils,
  ...
}:
{
  imports = [ ];

  clan.core.networking.targetHost = "152.53.139.179";
  networking.hostName = "clementine";

  networking.interfaces.ens3 = {
    ipv6.addresses = [
      {
        address = "2a0a:4cc0:c0:f339::";
        prefixLength = 64;
      }
    ];
  };

  services.qemuGuest.enable = true;

  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      80
      443
      22
    ];
  };

  # Kimai time tracking
  services.kimai = {
    webserver = "nginx";
    sites."kimai.megaclan3000.de" = {
      database.createLocally = true;
    };
  };

  # Disable nginx — Caddy handles everything
  services.nginx.enable = lib.mkForce false;

  # Override PHP-FPM socket ownership and service group to caddy (instead of nginx)
  services.phpfpm.pools."kimai-kimai.megaclan3000.de" = {
    user = lib.mkForce "kimai";
    group = lib.mkForce "caddy";
    settings = {
      "listen.owner" = lib.mkForce "caddy";
      "listen.group" = lib.mkForce "caddy";
    };
  };
  users.users.kimai.group = lib.mkForce "caddy";
  systemd.services."kimai-init-kimai.megaclan3000.de".serviceConfig.Group = lib.mkForce "caddy";
  systemd.tmpfiles.rules = lib.mkForce [
    "d '/var/lib/kimai/kimai.megaclan3000.de' 0770 kimai caddy - -"
  ];

  # Backup kimai state (database + files) via Clan
  clan.core.state."kimai" = {
    folders = [
      "/var/lib/kimai"
    ];
    preBackupScript = ''
      export PATH=${lib.makeBinPath [ config.systemd.package ]}
      systemctl stop kimai-init-kimai.megaclan3000.de.service
    '';
    postBackupScript = ''
      export PATH=${lib.makeBinPath [ config.systemd.package ]}
      systemctl start kimai-init-kimai.megaclan3000.de.service
    '';
  };

  # Punchcard time tracking
  clan.core.vars.generators."punchcard" = pinpox-utils.mkEnvGenerator [
    "OIDC_ISSUER_URL"
    "OIDC_CLIENT_ID"
    "OIDC_CLIENT_SECRET"
  ];

  systemd.services.punchcard = {
    description = "Punchcard time tracking";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${punchcard.packages.x86_64-linux.punchcard}/bin/punchcard";
      DynamicUser = true;
      StateDirectory = "punchcard";
      WorkingDirectory = "/var/lib/punchcard";
      Restart = "always";
      RestartSec = 5;
      EnvironmentFile = [ config.clan.core.vars.generators."punchcard".files."envfile".path ];
    };
    environment = {
      PORT = "8099";
      DATABASE_URL = "/var/lib/punchcard/punchcard.db";
      OIDC_REDIRECT_URL = "https://punchcard.megaclan3000.de/callback";
      SNOWFLAKES = "true";
    };
  };

  # Backup punchcard state via Clan
  clan.core.state."punchcard" = {
    folders = [
      "/var/lib/punchcard"
    ];
  };

  services.caddy = {
    enable = true;
    virtualHosts = {
      "megaclan3000.de".extraConfig = ''
        root * ${mc3000.packages.x86_64-linux.mc3000}
        file_server
        encode zstd gzip
      '';

      "punchcard.megaclan3000.de".extraConfig = ''
        reverse_proxy localhost:8099
      '';

      "kimai.megaclan3000.de".extraConfig = ''
        root * ${config.services.nginx.virtualHosts."kimai.megaclan3000.de".root}

        php_fastcgi unix/${config.services.phpfpm.pools."kimai-kimai.megaclan3000.de".socket} {
          env front_controller_active true
        }

        encode zstd gzip
        file_server
      '';
    };
  };
}
