{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.nostr-relay;
in
{

  options.pinpox.services.nostr-relay = {

    enable = mkEnableOption "Nostr relay stack (general relay, NIP-29 groups)";

    # ── General relay (strfry) ──────────────────────────────────────────────

    general = {
      domain = mkOption {
        type = types.str;
        description = "Domain for the general-purpose Nostr relay";
        example = "nostr.0cx.de";
      };

      port = mkOption {
        type = types.port;
        default = 7777;
        description = "Port for strfry to listen on";
      };
    };

    # ── NIP-29 groups relay (khatru29) ──────────────────────────────────────

    groups = {
      enable = mkEnableOption "NIP-29 groups relay";

      domain = mkOption {
        type = types.str;
        description = "Domain for the NIP-29 groups relay";
        example = "nostr-groups.0cx.de";
      };

      port = mkOption {
        type = types.port;
        default = 2929;
        description = "Port for the groups relay to listen on";
      };

      relayName = mkOption {
        type = types.str;
        default = "NIP-29 Groups Relay";
        description = "Relay display name";
      };

      relayDescription = mkOption {
        type = types.str;
        default = "A relay for NIP-29 group chats";
        description = "Relay description";
      };

      privateKeyFile = mkOption {
        type = types.path;
        description = "Path to a file containing the relay's private key (hex)";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/nostr-groups-relay";
        description = "Directory for the groups relay database";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [

    # ── General relay (strfry) ────────────────────────────────────────────

    {
      environment.etc."strfry.conf" = {
        text = ''
          db = "/var/lib/strfry/"

          relay {
            bind = "127.0.0.1"
            port = ${toString cfg.general.port}

            info {
              name = "Nostr Relay on ${cfg.general.domain}"
              description = "A general-purpose Nostr relay"
              contact = ""
            }

            nofiles = 0
            maxWebsocketPayloadSize = 131072
            autoPingSeconds = 55
            enableTCPKeepalive = false

            writePolicy {
              plugin = ""
            }
          }
        '';
      };

      systemd.services.strfry = {
        description = "strfry Nostr relay";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.strfry}/bin/strfry --config=/etc/strfry.conf relay";
          Restart = "on-failure";
          RestartSec = 5;

          DynamicUser = true;
          StateDirectory = "strfry";

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectControlGroups = true;
          ReadWritePaths = [ "/var/lib/strfry" ];
        };
      };

      services.caddy.virtualHosts."${cfg.general.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString cfg.general.port}
      '';
    }

    # ── NIP-29 groups relay (khatru29) ────────────────────────────────────

    (mkIf cfg.groups.enable {
      systemd.services.nostr-groups-relay = {
        description = "NIP-29 groups relay (khatru29)";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];

        environment = {
          PORT = toString cfg.groups.port;
          DOMAIN = cfg.groups.domain;
          RELAY_NAME = cfg.groups.relayName;
          RELAY_DESCRIPTION = cfg.groups.relayDescription;
          DATABASE_PATH = "${cfg.groups.dataDir}/db";
        };

        script = ''
          export RELAY_PRIVKEY="$(cat ''${CREDENTIALS_DIRECTORY}/privkey)"
          exec ${pkgs.groups-relay}/bin/groups-relay
        '';

        serviceConfig = {
          Type = "simple";
          LoadCredential = "privkey:${cfg.groups.privateKeyFile}";
          Restart = "on-failure";
          RestartSec = 5;

          DynamicUser = true;
          StateDirectory = "nostr-groups-relay";

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ReadWritePaths = [ cfg.groups.dataDir ];
        };
      };

      systemd.tmpfiles.rules = [
        "d ${cfg.groups.dataDir} 0700 - - -"
      ];

      services.caddy.virtualHosts."${cfg.groups.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString cfg.groups.port}
      '';
    })
  ]);
}
