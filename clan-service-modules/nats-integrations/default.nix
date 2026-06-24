{ lib, ... }:
# One clan service for all NATS ingestion workloads. Each integration is a
# ROLE; assign it to a machine and parameterize via settings. Adding the next
# integration is "add a role", never a new clan service.
#
# Each role OWNS its NKEY identity: it declares its own key generator (via
# ../nats/nkey.nix), so the secret seed lands only on the machine(s) the role
# runs on. The matching public key is authorized on the broker by adding a
# `roles.server.settings.authorizations.<name> = { keyGenerator; permissions; }`
# entry in the `@pinpox/nats` instance, referencing the same `keyGenerator`.
let
  metricType = lib.types.submodule {
    options = {
      subject = lib.mkOption {
        type = lib.types.str;
        description = "NATS subject to publish this metric's value to.";
        example = "home.rooms.study.temperature";
      };
      unit = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Unit string included in the published JSON payload.";
        example = "°C";
      };
    };
  };

  # Options every role shares. `keyName` is the role's NKEY identity; its
  # generator defaults to `nats-key-<keyName>` (override only to publish as a
  # different identity), matching the server `authorizations.<keyName>` entry.
  commonOptions = keyName: {
    keyGenerator = lib.mkOption {
      type = lib.types.str;
      default = "nats-key-${keyName}";
      description = ''
        Name of the NKEY generator this role creates and publishes as.
        Defaults to `nats-key-${keyName}`. Authorize it on the broker with a
        matching `roles.server.settings.authorizations` entry (same
        keyGenerator).
      '';
    };
    natsUrl = lib.mkOption {
      type = lib.types.str;
      default = "nats://nats.pin:4222";
      description = "NATS server URL to publish to.";
    };
  };
in
{
  _class = "clan.service";
  manifest.name = "nats-integrations";
  manifest.description = "NATS ingestion workloads, one role per integration.";
  manifest.readme = ''
    NATS ingestion workloads — one role per integration. Each role owns its
    NKEY (declares the generator via ../nats/nkey.nix; the seed lands only on
    the machine the role runs on) and publishes under `host.<hostname>.*` or
    its own subject root. Authorize each in the `@pinpox/nats` server's
    `authorizations` with the matching `keyGenerator`.

    Roles: host-reporter (boot/shutdown), ssh-logger (sshd auth events),
    nixos-reporter (generation activations), sensor-poller (ESPHome metrics),
    zulip-bridge (Zulip message feed).
  '';
  manifest.categories = [ "Utility" ];

  roles.host-reporter = {
    description = "Publishes machine boot (up) and clean-shutdown (down) events to NATS.";
    interface =
      { lib, ... }:
      {
        options = commonOptions "host-reporter";
      };
    perInstance =
      { instanceName, settings, ... }:
      {
        nixosModule = import ./host-reporter.nix { inherit instanceName settings; };
      };
  };

  roles.ssh-logger = {
    description = "Publishes sshd auth events (logins, failures, scans) to NATS.";
    interface =
      { lib, ... }:
      {
        options = commonOptions "ssh-logger";
      };
    perInstance =
      { instanceName, settings, ... }:
      {
        nixosModule = import ./ssh-logger.nix { inherit instanceName settings; };
      };
  };

  roles.nixos-reporter = {
    description = "Publishes NixOS generation activations (rebuilds) to NATS.";
    interface =
      { lib, ... }:
      {
        options = commonOptions "nixos-reporter";
      };
    perInstance =
      { instanceName, settings, ... }:
      {
        nixosModule = import ./nixos-reporter.nix { inherit instanceName settings; };
      };
  };

  roles.sensor-poller = {
    description = "Polls an ESPHome `/metrics` endpoint and publishes readings to NATS.";
    interface =
      { lib, ... }:
      {
        options = commonOptions "home-sensors" // {
          sensorUrl = lib.mkOption {
            type = lib.types.str;
            description = "Base URL of the ESPHome device (its `/metrics` is scraped).";
            example = "http://192.168.101.103";
          };
          interval = lib.mkOption {
            type = lib.types.str;
            default = "5min";
            description = "Poll interval (systemd `OnUnitActiveSec`).";
          };
          metrics = lib.mkOption {
            type = lib.types.attrsOf metricType;
            description = "Map of ESPHome metric id → { subject; unit; }.";
            example = lib.literalExpression ''
              { "temp-02" = { subject = "home.rooms.study.temperature"; unit = "°C"; }; }
            '';
          };
        };
      };
    perInstance =
      { instanceName, settings, ... }:
      {
        nixosModule = import ./sensor-poller.nix { inherit instanceName settings; };
      };
  };

  roles.zulip-bridge = {
    description = "Mirrors your Zulip message feed into NATS via the events API.";
    interface =
      { lib, ... }:
      {
        options = commonOptions "zulip-bridge" // {
          subjectRoot = lib.mkOption {
            type = lib.types.str;
            description = "Subject prefix; channel messages → `<root>.<stream_id>`, DMs → `<root>.dm`.";
            example = "chat.io.geninf.zulip";
          };
          includeDms = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to publish direct messages (else channels only).";
          };
        };
      };
    perInstance =
      { instanceName, settings, ... }:
      {
        nixosModule = import ./zulip-bridge.nix { inherit instanceName settings; };
      };
  };
}
