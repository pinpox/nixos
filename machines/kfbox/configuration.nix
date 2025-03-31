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

  lollypops.secrets.files."ente/credentials.yaml" = {
    owner = "ente";
    group-name = "ente";
    path = "/var/lib/ente/crendentials.yaml";
  };

  services.ente =
    let
      envfile = pkgs.writeTextFile {
        name = "env";
        text = '''';
      };
    in
    {

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

      enable = true;
      environmentFile = envfile;
      credentialsFile = "${config.lollypops.secrets.files."ente/credentials.yaml".path}";
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
    #retiolum.nixosModules.ca
    go-karma-bot.nixosModules.go-karma-bot
    aoe-taunt-discord-bot.nixosModules.aoe-taunt-discord-bot
  ];

  systemd.services.NetworkManager-wait-online = {
    serviceConfig = {
      ExecStart = [ "${pkgs.networkmanager}/bin/nm-online -q" ];
    };
  };

  # Karmabot for IRC channel

  clan.core.vars.generators."go-karma-bot" = pinpox-utils.mkEnvGenerator [
    "IRC_BOT_SERVER"
    "IRC_BOT_CHANNEL"
    "IRC_BOT_NICK"
    "IRC_BOT_PASS"
  ];

  lollypops.secrets.files."go-karma-bot/envfile" = { };
  services.go-karma-bot.environmentFile = config.lollypops.secrets.files."go-karma-bot/envfile".path;
  services.go-karma-bot.enable = true;

  # Discord AoE2 taunt bot
  lollypops.secrets.files."aoe-taunt-discord-bot/discord_token" = { };
  services.aoe-taunt-discord-bot.discordTokenFile =
    config.lollypops.secrets.files."aoe-taunt-discord-bot/discord_token".path;
  services.aoe-taunt-discord-bot.enable = true;

  pinpox = {

    server = {
      enable = true;
      hostname = "kfbox";
      stateVersion = "22.05";
    };

    wg-client = {
      enable = true;
      clientIp = "192.168.7.5";
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
      gitea.enable = true;
      owncast.enable = false;
      vikunja.enable = false;
      wastebin.enable = true;
    };

    metrics.node.enable = true;
  };

  programs.ssh.startAgent = false;
  services.qemuGuest.enable = true;

  # Setup Yubikey SSH and GPG
  services.pcscd.enable = true;

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
