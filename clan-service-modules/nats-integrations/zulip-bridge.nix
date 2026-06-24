{ instanceName, settings }:
{
  config,
  pkgs,
  lib,
  ...
}:
# Mirrors your Zulip message feed into NATS via the real-time events API.
# Runs under YOUR personal Zulip API key (the `.zuliprc` secret) as a pure,
# read-only observer: it registers its own event queue and long-polls it, so
# it never marks messages read, never touches presence, and is invisible to
# coworkers. Channel messages → `<root>.<stream_id>`, DMs → `<root>.dm`.
# Owns its NATS NKEY (declares the generator; seed lands only here).
let
  seedPath = config.clan.core.vars.generators.${settings.keyGenerator}.files.seed.path;
  zuliprcPath = config.clan.core.vars.generators."zulip-${instanceName}".files.zuliprc.path;

  pythonEnv = pkgs.python3.withPackages (ps: [ ps.zulip ]);

  bridge = pkgs.writeText "nats-zulip-bridge.py" ''
    import json
    import os
    import subprocess

    import zulip

    client = zulip.Client(config_file=os.environ["ZULIPRC"])
    root = os.environ["SUBJECT_ROOT"]
    include_dms = os.environ.get("INCLUDE_DMS", "1") == "1"


    def on_event(event):
        if event.get("type") != "message":
            return
        m = event["message"]
        if m["type"] == "stream":
            subject = f"{root}.{m['stream_id']}"
        else:
            if not include_dms:
                return
            subject = f"{root}.dm"
        payload = json.dumps(
            {
                "id": m["id"],
                "sender": m["sender_full_name"],
                "sender_email": m["sender_email"],
                "channel": m.get("display_recipient"),
                "topic": m.get("subject"),
                "content": m["content"],
                "ts": m["timestamp"],
                "type": m["type"],
            },
            ensure_ascii=False,
        )
        subprocess.run(["nats", "pub", subject, payload], check=False)


    # Blocks; registers an event queue and long-polls it, re-registering on
    # queue expiry. event_types=["message"] mirrors exactly what this account
    # sees (its channel subscriptions + DMs) — no all_public_streams.
    client.call_on_each_event(on_event, event_types=["message"])
  '';
in
{
  clan.core.vars.generators = {
    # NATS publish identity (seed local to this machine).
    ${settings.keyGenerator} = import ../nats/nkey.nix {
      inherit pkgs;
      owner = "root";
    };
    # Your personal .zuliprc (email + key + site), supplied once via
    # `clan vars generate`. Secret: this key can impersonate you in Zulip.
    "zulip-${instanceName}" = {
      files.zuliprc = {
        secret = true;
        mode = "0400";
      };
      prompts.zuliprc = {
        persist = true;
        type = "multiline";
        description = "Contents of your .zuliprc (the [api] block: email/key/site). Grants full account access — store carefully.";
      };
    };
  };

  systemd.services.nats-zulip-bridge = {
    description = "Mirror Zulip messages into NATS (${instanceName})";
    after = [
      "network-online.target"
      "nats.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.natscli ];
    serviceConfig = {
      DynamicUser = true;
      LoadCredential = [
        "zuliprc:${zuliprcPath}"
        "nkey:${seedPath}"
      ];
      Environment = [
        "ZULIPRC=%d/zuliprc"
        "NATS_URL=${settings.natsUrl}"
        "NATS_NKEY=%d/nkey"
        "SUBJECT_ROOT=${settings.subjectRoot}"
        "INCLUDE_DMS=${if settings.includeDms then "1" else "0"}"
      ];
      ExecStart = "${pythonEnv}/bin/python3 ${bridge}";
      Restart = "always";
      RestartSec = "10s";
    };
  };
}
