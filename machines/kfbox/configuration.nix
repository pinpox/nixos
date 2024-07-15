{
  aoe-taunt-discord-bot,
  config,
  go-karma-bot,
  mc3000,
  pkgs,
  retiolum,
  ...
}:
{

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

      settings = {
        internal.admins = [ "1580559962386438" ];
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

  networking.retiolum = {
    ipv4 = "10.243.100.102";
    ipv6 = "42:0:3c46:3ae6:90a8:b220:e772:8a5c";
  };

  lollypops.secrets.files = {
    "retiolum/rsa_priv" = { };
    "retiolum/ed25519_priv" = { };
  };

  services.tinc.networks.retiolum = {
    rsaPrivateKeyFile = "${config.lollypops.secrets.files."retiolum/rsa_priv".path}";
    ed25519PrivateKeyFile = "${config.lollypops.secrets.files."retiolum/ed25519_priv".path}";
  };

  lollypops.deployment.ssh.host = "46.38.242.17";

  services.logind.extraConfig = ''
    RuntimeDirectorySize=20G
  '';

  imports = [
    ./hardware-configuration.nix
    retiolum.nixosModules.retiolum
    #retiolum.nixosModules.ca
    go-karma-bot.nixosModules.go-karma-bot
    aoe-taunt-discord-bot.nixosModules.aoe-taunt-discord-bot
  ];

  # Often hangs
  # https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1660635001
  # systemd.services.NetworkManager-wait-online.enable = lib.mkForce
  #   false;
  # systemd.services.systemd-networkd-wait-online.enable = lib.mkForce
  #   false;
  systemd.services.NetworkManager-wait-online = {
    serviceConfig = {
      ExecStart = [
        ""
        "${pkgs.networkmanager}/bin/nm-online -q"
      ];
    };
  };

  # Karmabot for IRC channel
  lollypops.secrets.files."go-karma-bot/envfile" = { };
  services.go-karma-bot.environmentFile = config.lollypops.secrets.files."go-karma-bot/envfile".path;
  services.go-karma-bot.enable = false;

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

      hedgedoc.enable = true;
      miniflux.enable = true;
      thelounge.enable = true;
      kf-homepage.enable = true;
      gitea.enable = true;
      owncast.enable = false;
      vikunja.enable = true;
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

      #   let
      #
      #     ente-web-package = with pkgs; stdenv.mkDerivation rec {
      #
      #       pname = "ente-web";
      #       version = "0.9.5";
      #
      #       src = fetchFromGitHub
      #         {
      #           owner = "ente-io";
      #           repo = "ente";
      #           sparseCheckout = [ "web" ];
      #           rev = "photos-v${version}";
      #           fetchSubmodules = true;
      #           hash = "sha256-YJuhdMrgOQW4+LaxEvZNmFZDlFRBmPZot8oUdACdhhE=";
      #         }
      #       + "/web";
      #
      #       offlineCache = fetchYarnDeps {
      #         yarnLock = "${src}/yarn.lock";
      #         hash = "sha256-ZGZkpHZD2LoMIXzpQRAO4Fh9Jf4WxosgykKnn7I1+2g=";
      #       };
      #
      #       nativeBuildInputs = [
      #         yarnConfigHook
      #         yarnBuildHook
      #         nodejs
      #       ];
      #
      #       installPhase = ''
      #         cp -r apps/photos/out $out
      #       '';
      #
      #       meta = {
      #         description = "Web client for Ente Photos";
      #         homepage = "https://ente.io/";
      #         license = lib.licenses.agpl3Only;
      #         maintainers = with lib.maintainers; [
      #           surfaceflinger
      #           pinpox
      #         ];
      #         platforms = lib.platforms.all;
      #       };
      #     };
      #
      #   in
      #
      #   ''
      #
      #  handle_path /api/* {
      #       reverse_proxy 127.0.0.1:8080
      #  }
      #
      #  root * ${ente-web-package}
      #   file_server
      #   encode zstd gzip
      # '';

      "paste.0cx.de".extraConfig = "reverse_proxy ${config.services.wastebin.settings.WASTEBIN_ADDRESS_PORT}";
    };
  };
}
