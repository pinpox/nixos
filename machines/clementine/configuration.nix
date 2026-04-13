{
  mc3000,
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

  pinpox.services.twitch-first.enable = true;

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

  # Punchcard OIDC secrets (services managed via clan inventory)
  clan.core.vars.generators."punchcard" = pinpox-utils.mkEnvGenerator [
    "OIDC_ISSUER_URL"
    "OIDC_CLIENT_ID"
    "OIDC_CLIENT_SECRET"
  ];
  clan.core.vars.generators."punchcard2" = pinpox-utils.mkEnvGenerator [
    "OIDC_ISSUER_URL"
    "OIDC_CLIENT_ID"
    "OIDC_CLIENT_SECRET"
  ];

  services.caddy = {
    enable = true;
    virtualHosts = {
      "megaclan3000.de".extraConfig = ''
        root * ${mc3000.packages.x86_64-linux.mc3000}
        file_server
        encode zstd gzip
      '';
    };
  };
}
