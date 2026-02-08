{ ... }:
{
  _class = "clan.service";
  manifest.name = "thelounge";
  manifest.description = "The Lounge IRC client and bouncer";
  manifest.readme = "Self-hosted IRC client and bouncer with web interface";
  manifest.categories = [ "Communication" ];
  manifest.exports.out = [ "endpoints" ];

  roles.default = {
    description = "Sets up The Lounge IRC client with caddy reverse proxy";
    interface =
      { lib, meta, ... }:
      {
        options = {
          host = lib.mkOption {
            type = lib.types.str;
            default = "irc.${meta.domain}";
            description = "Host serving the The Lounge instance.";
          };
        };
      };

    perInstance =
      {
        settings,
        mkExports,
        ...
      }:
      {
        exports = mkExports { endpoints.hosts = [ settings.host ]; };

        nixosModule =
          { config, ... }:
          {
            config = {
              # Reverse proxy
              services.caddy = {
                enable = true;
                virtualHosts."${settings.host}".extraConfig =
                  "reverse_proxy 127.0.0.1:${toString config.services.thelounge.port}";
              };

              # Set up The Lounge
              services.thelounge = {
                enable = true;
                port = 9090;
                public = false;
                extraConfig = {
                  host = "127.0.0.1";
                  reverseProxy = true;
                  storagePolicy = {
                    enabled = true;
                    maxAgeDays = 365;
                    deletionPolicy = "everything";
                  };
                  theme = "morning";
                };
              };

              # Backup paths
              pinpox.services.restic-client.backup-paths-offsite = [
                "/var/lib/thelounge/certificates"
                "/var/lib/thelounge/config.js"
                # Don't backup logs for now - too big.
                # "/var/lib/thelounge/logs"
                # "/var/lib/thelounge/packages"
                "/var/lib/thelounge/sts-policies.json"
                "/var/lib/thelounge/users"
                "/var/lib/thelounge/vapid.json"
              ];
            };
          };
      };
  };
}
