{ ... }:
{
  # Original bot on matrix.org/porree (kept verbatim; name = container/state dir).
  opencrow-claude = {
    module.input = "self";
    module.name = "@pinpox/opencrow";
    roles.default.machines.porree.settings.environment = {
      # Personal contacts: Stalwart CardDAV (clementine); the work Nextcloud
      # keeps its addressbook. Calendars are not configured here — plann reads
      # them from the generated ~/.config/calendar.conf below.
      STALWART_URL = "https://mail.pinpox.com";
      STALWART_USER = "pinpox@pinpox.com";
      STALWART_ADDRESSBOOK = "default";
      WORK_NEXTCLOUD_URL = "https://nextcloud.clan.lol";
      WORK_NEXTCLOUD_USER = "pinpox";
      OPENCROW_MATRIX_HOMESERVER = "https://matrix.org";
      OPENCROW_MATRIX_USER_ID = "@p.i.m.p.:matrix.org";
      OPENCROW_ALLOWED_USERS = "@pinpox:matrix.org";
      OPENCROW_HEARTBEAT_INTERVAL = "30m";
    };
    roles.default.extraModules = [
      (
        {
          config,
          pkgs,
          flake-self,
          pinpox-utils,
          ...
        }:
        let
          instance = config.services.opencrow.instances.claude;
          stateDir = "/var/lib/opencrow-claude";
          plann = flake-self.inputs.skill-collection.packages.${pkgs.stdenv.hostPlatform.system}.plann;

          # plann's config: one section per calendar. Passwords are read from
          # the unit's environment (EnvironmentFile) instead of the store.
          # plann runs the command through `sh -c`, so `printenv` is spelled
          # out — PATH is whatever the caller happens to have.
          printenv = "${pkgs.coreutils}/bin/printenv";
          calendarConf = (pkgs.formats.yaml { }).generate "calendar.conf" {
            default = {
              caldav_url = "https://mail.pinpox.com/dav/cal/";
              caldav_user = "pinpox@pinpox.com";
              caldav_pass_command = "${printenv} STALWART_PASSWORD";
              calendar_url = "default";
            };
            weightlifting = {
              inherits = "default";
              calendar_url = "weightlifting";
            };
            work = {
              caldav_url = "https://nextcloud.clan.lol/remote.php/dav/";
              caldav_user = "pinpox";
              caldav_pass_command = "${printenv} WORK_NEXTCLOUD_PASSWORD";
              calendar_url = "personal";
            };
          };
        in
        {
          clan.core.vars.generators."opencrow-stalwart" = pinpox-utils.mkEnvGenerator [
            "STALWART_PASSWORD"
          ];
          clan.core.vars.generators."opencrow-nextcloud-work" = pinpox-utils.mkEnvGenerator [
            "WORK_NEXTCLOUD_PASSWORD"
          ];
          clan.core.vars.generators."opencrow-eversports" = pinpox-utils.mkEnvGenerator [
            "EVERSPORTS_EMAIL"
            "EVERSPORTS_PASSWORD"
          ];
          # Integration env files, appended to the bot's token file (lists merge).
          services.opencrow.instances.claude.environmentFiles = [
            config.clan.core.vars.generators."opencrow-stalwart".files.envfile.path
            config.clan.core.vars.generators."opencrow-nextcloud-work".files.envfile.path
            config.clan.core.vars.generators."opencrow-eversports".files.envfile.path
          ];

          # Calendars run through plann's CLI + its skill. Defining any key of
          # `skills` drops the option default, so `web` is restated here.
          services.opencrow.instances.claude.extraPackages = [ plann ];
          services.opencrow.instances.claude.skills = {
            web = "${instance.package}/share/opencrow/skills/web";
            plann = "${plann}/share/skills/plann";
          };

          # plann reads ~/.config/calendar.conf, and HOME is the bot's state
          # dir. The rule has to run INSIDE the container: the state dir is
          # owned by the container's `opencrow` user, and host-side tmpfiles
          # refuse to descend from it into a root-owned child ("unsafe path
          # transition") and silently skip the symlink.
          containers.opencrow-claude.config = {
            systemd.tmpfiles.rules = [
              "d ${stateDir}/.config 0750 opencrow opencrow -"
              "L+ ${stateDir}/.config/calendar.conf - - - - ${calendarConf}"
            ];
          };
        }
      )
    ];
  };
}
