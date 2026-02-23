{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.pinpox.services.nostr-relay-rs;
in
{

  options.pinpox.services.nostr-relay-rs = {
    enable = mkEnableOption "nostr-rs-relay Nostr relay";

    domain = mkOption {
      type = types.str;
      description = "Domain for the Nostr relay Caddy virtual host";
    };

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Extra settings merged into services.nostr-rs-relay.settings";
    };
  };

  config = mkIf cfg.enable {

    services.nostr-rs-relay = {
      enable = true;
      settings = lib.recursiveUpdate {
        info = {
          relay_url = "wss://${cfg.domain}/";
          name = "nostr-rs-relay on ${cfg.domain}";
          description = "A Nostr relay running nostr-rs-relay";
        };
        network = {
          address = "127.0.0.1";
          remote_ip_header = "x-forwarded-for";
        };
        limits = {
          messages_per_sec = 3;
          subscriptions_per_min = 10;
          max_event_bytes = 131072;
          max_ws_message_bytes = 131072;
          max_ws_frame_bytes = 131072;
          broadcast_buffer = 16384;
          event_persist_buffer = 4096;
        };
        authorization = {
          nip42_auth = true;
          nip42_dms = true;
        };
        verified_users = {
          mode = "disabled";
        };
        options = {
          reject_future_seconds = 1800;
        };
      } cfg.settings;
    };

    services.caddy = {
      enable = true;
      virtualHosts."${cfg.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString config.services.nostr-rs-relay.port}
      '';
    };
  };
}
