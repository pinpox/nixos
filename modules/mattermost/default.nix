{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.pinpox.services.mattermost;

  default_files = pkgs.writeTextFile {
    name = "default.json";
    text = builtins.readFile ./default.json;
  };
in {

  options.pinpox.services.mattermost = {
    enable = mkEnableOption "Mattermost server";
  };

  config = mkIf cfg.enable {

    # TODO set up IRC bridge
    # TODO setup reverse-proxy

    users.users."mattermost" = {
      createHome = true;
      description = "Mattermost service user";
      group = "mattermost";
      home = "/var/lib/mattermost";
      isSystemUser = true;
      # uid = config.ids.uids.mattermost;
    };

    users.groups."mattermost" = { };

    services.postgresql.enable = true;

    # The systemd service will fail to execute the preStart hook
    # if the WorkingDirectory does not exist

    system.activationScripts.mattermost = ''
      mkdir -p /var/lib/mattermost
    '';

    systemd.services.mattermost = {
      description = "Mattermost chat service";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "postgresql.service" ];

      preStart = ''
        mkdir -p /var/lib/mattermost/{data,config,logs,client-plugins,files}

        # For mutable config
        if ! test -e "/var/lib/mattermost/config/.initial-created"; then
          rm -f /var/lib/mattermost/config/config.json
          rm -rf /var/lib/mattermost/{bin,fonts,i18n,templates,client}
          cp ${default_files} /var/lib/mattermost/config/config.json
          cp -r ${pkgs.mattermost}/{bin,fonts,i18n,templates,client} /var/lib/mattermost
          touch /var/lib/mattermost/config/.initial-created
        fi

        # Create Database if not alaredy there
        if ! test -e "/var/lib/mattermost/.db-created"; then
          ${pkgs.sudo}/bin/sudo -u ${config.services.postgresql.superUser} \
            ${config.services.postgresql.package}/bin/psql postgres -c \
              "CREATE ROLE mattermost WITH LOGIN NOCREATEDB NOCREATEROLE ENCRYPTED PASSWORD '$MM_EXTRA_SQLSETTINGS_DB_PASSWORD'"
          ${pkgs.sudo}/bin/sudo -u ${config.services.postgresql.superUser} \
            ${config.services.postgresql.package}/bin/createdb \
              --owner mattermost mattermost
          touch /var/lib/mattermost/.db-created
        fi

        chown mattermost:mattermost -R /var/lib/mattermost
        chmod u+rw,g+r,o-rwx -R /var/lib/mattermost
      '';

      serviceConfig = {
        PermissionsStartOnly = true;
        User = "mattermost";
        Group = "mattermost";

        EnvironmentFile = /var/src/secrets/mattermost/envfile;

        # TODO Extract non-secrets from envfile and put them here instead
        Environment = [

          "MM_SERVICESETTINGS_ENABLEEMAILINVITATIONS=true"
          ''MM_SERVICESETTINGS_LISTENADDRESS="127.0.0.1:8065"''
          "MM_SERVICESETTINGS_ENABLEOAUTHSERVICEPROVIDER=true"
          "MM_SERVICESETTINGS_SITEURL='https://mm.0cx.de'"
          # "MM_SERVICESETTINGS_WEBSOCKETURL='https://mm.0cx.de'"
          # TODO Check syntax for header
          "MM_SERVICESETTINGS_TRUSTEDPROXYIPHEADER='[\"X-Forwarded-For\" \"X-Real-IP\"]'"

          "MM_FILESETTINGS_DIRECTORY='/var/lib/mattermost/files'"

          "MM_SQLSETTINGS_DRIVERNAME=postgres"

          "MM_SERVICESETTINGS_ALLOWCORSFROM='*'"
          # "MM_SERVICESETTINGS_CorsExposedHeaders": "",
          # "MM_SERVICESETTINGS_CorsDebug": false,

          # TODO Migrate data
          # MM_SQLSETTINGS_DRIVERNAME="mysql"

          # Secret envfile contains:
          # MM_EMAILSETTINGS_CONNECTIONSECURITY=
          # MM_EMAILSETTINGS_ENABLEPREVIEWMODEBANNER=
          # MM_EMAILSETTINGS_ENABLESMTPAUTH=
          # MM_EMAILSETTINGS_FEEDBACKEMAIL=
          # MM_EMAILSETTINGS_PUSHNOTIFICATIONCONTENTS=
          # MM_EMAILSETTINGS_REPLYTOADDRESS=
          # MM_EMAILSETTINGS_SENDEMAILNOTIFICATIONS=
          # MM_EMAILSETTINGS_SMTPPASSWORD=
          # MM_EMAILSETTINGS_SMTPPORT=
          # MM_EMAILSETTINGS_SMTPSERVER=
          # MM_EMAILSETTINGS_SMTPUSERNAME=
          # MM_FILESETTINGS_PUBLICLINKSALT=
          # MM_SQLSETTINGS_ATRESTENCRYPTKEY=
          # MM_SQLSETTINGS_DATASOURCE=

          # MM_EXTRA_SQLSETTINGS_DB_PASSWORD=

        ];

        ExecStart =
          "${pkgs.mattermost}/bin/mattermost -c /var/lib/mattermost/config/config.json";
        WorkingDirectory = "/var/lib/mattermost";
        Restart = "always";
        RestartSec = "10";
        LimitNOFILE = "49152";
      };
      unitConfig.JoinsNamespaceOf = "postgresql.service";
    };
  };

  # systemd.services.matterircd = {
  #   description = "Mattermost IRC bridge service";
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     User = "nobody";
  #     Group = "nogroup";
  #     ExecStart = "${pkgs.matterircd}/bin/matterircd ${concatStringsSep " " cfg.matterircd.parameters}";
  #     WorkingDirectory = "/tmp";
  #     PrivateTmp = true;
  #     Restart = "always";
  #     RestartSec = "5";
  #   };
  # };
}
