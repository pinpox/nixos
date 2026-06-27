# NATS broker + ingestion integrations. Auto-merged into inventory.nix's
# `instances`; opencrow.nix contributes the per-bot authorizations (deep-merged).
{ ... }:
{
  # Personal event firehose. kfbox runs the broker; it authorizes a set of public
  # keys (seeds live with whoever runs each identity). Every machine is a client.
  nats = {
    module.input = "self";
    module.name = "@pinpox/nats";

    roles.server.machines.kfbox.settings.host = "nats.pin";

    # Pure authorizer: each entry = a pubkey (by generator) + allowed topics.
    roles.server.settings.authorizations = {
      pinpox = {
        permissions = {
          publish.allow = [
            "personal.>"
            "team.pinpox.>"
            "project.>"
            "home.>"
            "user.pinpox.>"
            # Let pinpox assign tasks to any persona's trigger pipe.
            "opencrow.*.task"
          ];
          subscribe.allow = [ ">" ];
        };
      };
      host-reporter = {
        permissions.publish.allow = [ "host.*.status" ];
      };
      ssh-logger = {
        permissions.publish.allow = [ "host.*.ssh.>" ];
      };
      nixos-reporter = {
        permissions.publish.allow = [ "host.*.nixos.>" ];
      };
      home-sensors = {
        permissions.publish.allow = [ "home.>" ];
      };
      zulip-bridge = {
        permissions.publish.allow = [ "chat.io.geninf.zulip.>" ];
      };
    };

    # Every machine is a client: nats CLI + NATS_URL + the human pinpox login seed.
    roles.client.tags.all = { };
    roles.client.settings.loginUsers.pinpox = { };
  };

  # NATS ingestion workloads — one role per integration. Each role owns its NKEY
  # (declares the generator; seed only on its machine), authorized by the matching
  # `authorizations` entry above.
  nats-integrations = {
    module.input = "self";
    module.name = "@pinpox/nats-integrations";

    # Boot/clean-shutdown state → host.<hostname>.status (state in payload).
    roles.host-reporter.tags.all = { };
    # SSH auth events → host.<hostname>.ssh.<event>.
    roles.ssh-logger.tags.all = { };
    # NixOS generation activations → host.<hostname>.nixos.activated.
    roles.nixos-reporter.tags.all = { };

    # Study ESPHome sensor → home.rooms.study.*  (traube only).
    roles.sensor-poller.machines.traube.settings = {
      sensorUrl = "http://192.168.101.103";
      interval = "5min";
      metrics = {
        "temp-02" = {
          subject = "home.rooms.study.temperature";
          unit = "°C";
        };
        "ccs811_eco2_value" = {
          subject = "home.rooms.study.co2";
          unit = "ppm";
        };
      };
    };

    # Zulip feed → chat.io.geninf.zulip.*  (kfbox only).
    roles.zulip-bridge.machines.kfbox.settings = {
      subjectRoot = "chat.io.geninf.zulip";
      includeDms = true;
    };

    # MPRIS playback (play/pause/track) → user.pinpox.music
    roles.user-music-status.tags.desktop = { };
  };
}
