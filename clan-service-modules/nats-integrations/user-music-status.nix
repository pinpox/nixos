{ instanceName, settings }:
{
  config,
  pkgs,
  lib,
  ...
}:
# MPRIS → NATS music feed, USER-SPACE. Runs as `settings.user`'s systemd *user*
# service bound to graphical-session.target: MPRIS players live on the session
# bus, so this is inherently session-scoped and must NOT linger. Publishes one
# message per play/pause and track change to `user.<user>.music` (host is a
# payload field; an empty `status` means no player is active).
#
# Subjects are per-user namespaced (`user.<user>.…`) so several people in the
# clan can run their own feeds without collision, each authorized for only
# their own prefix. Subscribe `user.*.music` for everyone or `user.<user>.music`
# for one person.
#
# Identity: reuses the human NKEY the @pinpox/nats CLIENT role already deploys
# (nats-key-<user>, owner=<user>, share=true, present on every machine via
# tags.all), so it declares no generator of its own (that would clash with the
# client role). Authorize `user.<user>.>` for that key on the broker. The unit
# runs AS the seed's owner, reading the 0400 seed directly: no LoadCredential.
let
  seedPath = config.clan.core.vars.generators.${settings.keyGenerator}.files.seed.path;
  host = config.networking.hostName;
  subject = "user.${settings.user}.music";

  # playerctl 2.x has no JSON output, so fields are tab-delimited and jq builds
  # the payload (safe escaping + the timestamp). `--follow` re-prints on
  # play/pause, track change, and player appearance; an empty line (all players
  # gone) yields an all-empty payload. `--no-templates` stops nats from
  # interpreting `{{…}}` that might appear in a title.
  feed = pkgs.writeShellApplication {
    name = "nats-user-music-status";
    runtimeInputs = with pkgs; [
      playerctl
      jq
      natscli
    ];
    text = ''
      fmt=$'{{status}}\t{{playerName}}\t{{artist}}\t{{title}}\t{{album}}'
      playerctl metadata --follow --format "$fmt" |
        while IFS=$'\t' read -r status player artist title album; do
          nats pub --no-templates "$SUBJECT" "$(jq -cn \
            --arg status "$status" --arg player "$player" --arg artist "$artist" \
            --arg title "$title" --arg album "$album" --arg host "${host}" \
            '{status:$status,player:$player,artist:$artist,title:$title,album:$album,host:$host,ts:(now|todateiso8601)}')" || true
        done
    '';
  };
in
{
  systemd.user.services.nats-user-music-status = {
    description = "Publish MPRIS music status to NATS (${instanceName})";
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    # Globally-installed user unit, but a no-op in any manager but the owner's.
    unitConfig.ConditionUser = settings.user;
    serviceConfig = {
      # The client role's shellInit doesn't reach services, so NATS_* is set
      # explicitly. No LoadCredential: the unit runs as the seed owner.
      Environment = [
        "NATS_URL=${settings.natsUrl}"
        "NATS_NKEY=${seedPath}"
        "SUBJECT=${subject}"
      ];
      ExecStart = lib.getExe feed;
      Restart = "always";
      RestartSec = "5s";
    };
  };
}
