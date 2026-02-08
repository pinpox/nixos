{ ... }:
{
  _class = "clan.service";
  manifest.name = "navidrome";
  manifest.description = "Navidrome music streaming server";
  manifest.readme = "Self-hosted music streaming server with subsonic API";
  manifest.categories = [ "Media" ];
  manifest.exports.out = [ "endpoints" ];

  roles.default = {
    description = "Sets up navidrome music server with caddy reverse proxy";
    interface =
      { lib, ... }:
      {
        options = {

          # TODO When https://git.clan.lol/clan/clan-core/pulls/6727 gets
          # merged, we can just default to music.<meta.domain>
          host = lib.mkOption {
            type = lib.types.str;
            default = "music.0cx.de";
            description = "Host serving the navidrome instance";
            example = "party.0cx.de";
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
                  "reverse_proxy 127.0.0.1:${toString config.services.navidrome.settings.Port}";
              };

              # Mount storagebox
              pinpox.defaults.storagebox = {
                enable = true;
                mountOnAccess = false;
              };

              # Add navidrome user to storage-users group for access to storagebox
              users.users.navidrome.extraGroups = [ "storage-users" ];

              # Set up navidrome
              services.navidrome = {
                enable = true;
                settings.Port = 4533;
                settings.Address = "127.0.0.1";
                settings.MusicFolder = "${config.pinpox.defaults.storagebox.mountPoint}/music";
              };

              # Ensure storagebox is mounted before navidrome starts
              systemd.services.navidrome = {
                requires = [ "mnt-storagebox.mount" ];
                after = [ "mnt-storagebox.mount" ];
              };
            };
          };
      };
  };
}
