{
  mc3000,
  trippy-track,
  pinpox-utils,
  ...
}:
{
  imports = [ trippy-track.nixosModules.default ];

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

  pinpox.services.twitch-first.enable = true;
  pinpox.services.matrix-synapse.enable = true;

  clan.core.vars.generators."trippy-track" = pinpox-utils.mkEnvGenerator [
    "OIDC_ISSUER_URL"
    "OIDC_CLIENT_ID"
    "OIDC_CLIENT_SECRET"
    "OIDC_REDIRECT_URL"

    "VAPID_PRIVATE_KEY"
    "VAPID_PUBLIC_KEY"
    "VAPID_CONTACT"
  ];

  services.trippy-track = {
    enable = true;
    port = 8090;
    environmentFile = "/run/secrets/trippy-track/envfile";
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

  services.caddy = {
    enable = true;
    virtualHosts = {
      "megaclan3000.de".extraConfig = ''
        root * ${mc3000.packages.x86_64-linux.mc3000}
        file_server
        encode zstd gzip
      '';
      "travel.pinpox.com".extraConfig = ''
        reverse_proxy localhost:8090
      '';
    };
  };
}
