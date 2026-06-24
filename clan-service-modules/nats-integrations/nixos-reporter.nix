{ instanceName, settings }:
{
  config,
  pkgs,
  lib,
  ...
}:
# NixOS generation-activation reporter → NATS. A `.path` unit watches the
# system profile directory; whenever a new generation is activated (the
# profile changes), the oneshot runs and publishes `host.<hostname>.nixos.activated`
# — but only when the active generation actually CHANGES (deduped via a
# remembered toplevel in StateDirectory), so plain reboots of the same
# generation stay quiet (host-reporter's `up` covers those). The service also
# runs on boot to emit an initial report. The profile (not /run/current-system)
# is the source of truth for the just-activated generation. Owns its NKEY.
#
# NOTE: we deliberately do NOT use `restartTriggers = [ system.build.toplevel ]`
# — that is self-referential (toplevel is built from this unit) → infinite
# recursion. The path watch sidesteps it entirely.
let
  seedPath = config.clan.core.vars.generators.${settings.keyGenerator}.files.seed.path;
  host = config.networking.hostName;

  reporter = pkgs.writeShellApplication {
    name = "nats-nixos-reporter";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      jq
      natscli
    ];
    text = ''
      # shellcheck disable=SC2154  # STATE_DIRECTORY is set by systemd
      last_file="$STATE_DIRECTORY/last"
      profile=/nix/var/nix/profiles/system
      toplevel="$(readlink -f "$profile")"
      last="$(cat "$last_file" 2>/dev/null || true)"
      if [ "$toplevel" = "$last" ]; then
        exit 0  # same generation already reported (reboot, or a spurious watch hit)
      fi

      gen="$(readlink "$profile" 2>/dev/null | sed -nE 's,.*system-([0-9]+)-link,\1,p' || true)"
      label="$(cat "$profile/nixos-version" 2>/dev/null || echo unknown)"
      rev="$(cat "$profile/configuration-revision" 2>/dev/null || true)"
      system_hash="''${toplevel##*/}"   # store basename: <hash>-nixos-system-<host>-<label>
      system_hash="''${system_hash%%-*}"  # the 32-char store hash
      narhash="$(cat "$profile/flake-narhash" 2>/dev/null || true)"

      # Reboot needed if the booted system's kernel/initrd/modules/systemd
      # differ from the newly-activated one.
      reboot_required=false
      for c in kernel initrd kernel-modules systemd; do
        booted="$(readlink -f "/run/booted-system/$c" 2>/dev/null || true)"
        current="$(readlink -f "$profile/$c" 2>/dev/null || true)"
        if [ "$booted" != "$current" ]; then
          reboot_required=true
          break
        fi
      done

      payload="$(jq -cn \
        --arg gen "$gen" --arg toplevel "$toplevel" --arg system_hash "$system_hash" \
        --arg label "$label" --arg rev "$rev" --arg narhash "$narhash" \
        --arg host "${host}" --argjson reboot "$reboot_required" \
        --arg ts "$(date -u +%FT%TZ)" \
        '{event: "activated", generation: (if $gen == "" then null else ($gen | tonumber) end), toplevel: $toplevel, system_hash: $system_hash, label: $label, rev: $rev, narhash: $narhash, host: $host, reboot_required: $reboot, ts: $ts}')"

      # Record the new toplevel only once published, so a failed publish (NATS
      # unreachable) is retried on the next activation/boot.
      if nats pub "host.${host}.nixos.activated" "$payload"; then
        printf '%s\n' "$toplevel" > "$last_file"
      fi
    '';
  };
in
{
  clan.core.vars.generators.${settings.keyGenerator} = import ../nats/nkey.nix {
    inherit pkgs;
    owner = "root";
  };

  systemd.services.nats-nixos-reporter = {
    description = "Publish NixOS generation activations to NATS (${instanceName})";
    after = [
      "network-online.target"
      "nats.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ]; # initial/boot report (dedupe-guarded)
    serviceConfig = {
      Type = "oneshot";
      DynamicUser = true;
      StateDirectory = "nats-nixos-reporter";
      LoadCredential = [ "nkey:${seedPath}" ];
      Environment = [
        "NATS_URL=${settings.natsUrl}"
        "NATS_NKEY=%d/nkey"
      ];
      ExecStart = lib.getExe reporter;
    };
  };

  # Fire the reporter whenever the system profile changes (a generation is
  # activated). Spurious hits (e.g. GC trimming old generations) are absorbed
  # by the toplevel dedupe in the script.
  systemd.paths.nats-nixos-reporter = {
    wantedBy = [ "multi-user.target" ];
    pathConfig.PathModified = "/nix/var/nix/profiles";
  };
}
