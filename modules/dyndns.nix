{ config, pkgs, lib, ... }: {

  # The service in nixpkgs runs as cfdyndns:cfdyndns and can't read
  # /var/src/secrets. This is a workaround until
  # https://github.com/NixOS/nixpkgs/issues/107487 is fixed

  # services.cfdyndns = {
  #   enable = true;
  #   email = "cloudflare@pablo.tools";
  #   apikeyFile = "/var/src/secrets/cloudflare/token";
  #   records = [ "cloud.pablo.tools" ];
  # };

  systemd.timers.cfdyndns = {
    description = "CloudFlare Dynamic DNS timer";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    timerConfig = {
      OnUnitActiveSec = "30min";
      Unit = "cfdyndns.service";
    };
  };

  systemd.services.cfdyndns = {
    description = "CloudFlare Dynamic DNS Client";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    startAt = "5 minutes";
    serviceConfig = { Type = "simple"; };
    environment = {
      CLOUDFLARE_EMAIL = "cloudflare@pablo.tools";
      CLOUDFLARE_RECORDS = "cloud.pablo.tools";
    };
    script = ''
      export CLOUDFLARE_APIKEY="$(cat /var/src/secrets/cloudflare/token)"
      ${pkgs.cfdyndns}/bin/cfdyndns
    '';
  };
}
