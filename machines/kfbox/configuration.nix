{
  aoe-taunt-discord-bot,
  config,
  go-karma-bot,
  mc3000,
  pkgs,
  lib,
  ...
}:
let
  pinpox-utils = import ../../utils { inherit pkgs lib; };
in
{

  # Build on machine executing the clan
  clan.core.networking.buildHost = "pinpox@localhost";

  services.ente = {
    enable = true;
    web = true;
    albums = true;
    web-host = "https://photos.0cx.de";
    albums-host = "https://albums.0cx.de";
    api-host = "https://photos-api.0cx.de";
    webserver = "caddy";
    settings = {
      internal.admins = [ "1580559962386438" ];
      apps.public-albums = "https://albums.0cx.de";
    };
  };

  networking.interfaces.ens3 = {
    ipv6.addresses = [
      {
        address = "2a03:4000:7:4e0::";
        prefixLength = 64;
      }
    ];
  };

  clan.core.networking.targetHost = "46.38.242.17";

  services.logind.extraConfig = ''
    RuntimeDirectorySize=20G
  '';

  imports = [
    ./retiolum.nix
    ./hardware-configuration.nix
    go-karma-bot.nixosModules.go-karma-bot
    aoe-taunt-discord-bot.nixosModules.aoe-taunt-discord-bot
  ];

  systemd.services.NetworkManager-wait-online.serviceConfig.ExecStart = [
    "${pkgs.networkmanager}/bin/nm-online -q"
  ];

  # Karmabot for IRC channel
  clan.core.vars.generators."go-karma-bot" = pinpox-utils.mkEnvGenerator [
    "IRC_BOT_SERVER"
    "IRC_BOT_CHANNEL"
    "IRC_BOT_NICK"
    "IRC_BOT_PASS"
  ];

  services.go-karma-bot = {
    enable = true;
    environmentFile = config.clan.core.vars.generators."go-karma-bot".files."envfile".path;
  };

  # Discord AoE2 taunt bot
  clan.core.vars.generators."aoe-taunt-discord-bot" = {
    prompts.discord_token.persist = true;
  };

  services.aoe-taunt-discord-bot = {
    enable = true;
    discordTokenFile =
      config.clan.core.vars.generators."aoe-taunt-discord-bot".files."discord_token".path;
  };

  networking.hostName = "kfbox";

  pinpox = {

    server = {
      enable = true;
    };

    services = {
      # TODO Add miniflux and vikunja to dex
      # TODO Remove gitea apps
      dex.enable = true;
      dex.host = "login.0cx.de";

      caddy-security = {
        enable = true;
        domain = "0cx.de";
        openID = {
          name = "Dex";
          host = "login.0cx.de";
        };
      };

      radio.enable = true;
      jitsi-matrix-presence.enable = true;
      hedgedoc.enable = true;
      screego.enable = true;
      miniflux.enable = true;
      thelounge.enable = true;
      kf-homepage.enable = true;
      web-wm.enable = true;
      gitea.enable = true;
      owncast.enable = false;
      vikunja.enable = false;
      wastebin.enable = true;
    };

    metrics.node.enable = true;
  };

  programs.ssh.startAgent = false;
  services.qemuGuest.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
  };

  fileSystems."/tmp" = {
    fsType = "tmpfs";
    device = "tmpfs";
    options = [
      "nosuid"
      "nodev"
      "relatime"
      "size=14G"
    ];
  };

  boot.growPartition = true;
  boot.kernelParams = [ "console=ttyS0" ];
  boot.loader.grub.device = "/dev/sda";
  boot.loader.timeout = 0;

  security.acme.acceptTerms = true;
  security.acme.defaults.email = "letsencrypt@pablo.tools";

  # Block anything that is not HTTP(s) or SSH.
  networking.firewall = {
    enable = true;
    allowPing = true;
    allowedTCPPorts = [
      80
      443
      22
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

      "irc.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:9090";
      # "transfer.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:6767";
      "pads.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:3000";

      "photos-api.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:8080";

      # "matrixpresence.0cx.de".extraConfig = "reverse_proxy 127.0.0.1:8227";

      "paste.0cx.de".extraConfig =
        "reverse_proxy ${config.services.wastebin.settings.WASTEBIN_ADDRESS_PORT}";
    };
  };
}
