#!/usr/bin/env bash
# config-hash — per-machine "dirty/clean/offline" detector for this clan flake.
#
# Compares, for each machine, the config the CURRENT repo (clean OR dirty) would
# build against what the machine actually has deployed. Online => always
# verifiable: no git rev required.
#
# HOW IT WORKS
#   The flake exposes `configHashes.<host>`: the store-hash of that host's
#   `system.build.toplevel` with the three whole-flake couplings in
#   modules/nix-common (configurationRevision, systemBuilderCommands narHash
#   stamp, nix.registry) AND the config-hash writer itself neutralised. That
#   makes the hash a function of ONLY that host's own evaluated config —
#   unaffected by other hosts or by syntax-only edits, changing only when the
#   host's real config changes.
#   modules/config-hash writes this value into each machine's closure at
#   /run/current-system/config-hash. The tool reads it back over ssh.
#
#   repo side:     nix eval --raw .#configHashes.<host>
#   deployed side: ssh <host> cat /run/current-system/config-hash
#   dirty  := repo != deployed
#
# STATES:
#   clean      deployed config-hash == repo configHashes.<host>
#   dirty      they differ (repo would build something else for this host)
#   offline    host unreachable over ssh
#   stale      reachable but no /run/current-system/config-hash — deployed
#              BEFORE the config-hash module existed; redeploy once to fix
#   error      repo eval failed for this host
#
# Usage:
#   config-hash.sh status [host]        repo vs deployed: one host, or all (default)
#   config-hash.sh list                 machine names
#   config-hash.sh hash <host>          repo pure hash for one host
#
# ssh target is read from clan.core.networking.targetHost per machine.
# Env: SSH_USER (default root), JOBS (parallel hosts, default 6),
#      SSH_TIMEOUT (connect seconds, default 5).

set -euo pipefail

SSH_USER="${SSH_USER:-root}"
JOBS="${JOBS:-6}"
SSH_TIMEOUT="${SSH_TIMEOUT:-5}"
SSH_OPTS=(-o BatchMode=yes -o "ConnectTimeout=${SSH_TIMEOUT}" -o StrictHostKeyChecking=accept-new)

die() { echo "config-hash: $*" >&2; exit 1; }
have_jq() { command -v jq >/dev/null 2>&1; }

# Locate the flake working tree to diff against. It MUST be the live repo
# (possibly dirty) — never the immutable /nix/store copy this script may run
# from — so resolve $CONFIG_HASH_FLAKE, else walk up from $PWD to a flake.nix.
resolve_repo() {
  if [ -n "${CONFIG_HASH_FLAKE:-}" ]; then printf '%s' "$CONFIG_HASH_FLAKE"; return 0; fi
  local d="$PWD"
  while [ "$d" != "/" ]; do
    [ -e "$d/flake.nix" ] && { printf '%s' "$d"; return 0; }
    d="$(dirname "$d")"
  done
  return 1
}
REPO="$(resolve_repo)" || die "no flake.nix found — run inside the repo, or set CONFIG_HASH_FLAKE=/path/to/repo"

# Progress goes to stderr so a piped `status` still yields a clean table on
# stdout. Colors keyed on stderr being a tty.
if [ -t 2 ]; then
  P_G=$'\e[32m'; P_R=$'\e[31m'; P_Y=$'\e[33m'; P_B=$'\e[90m'; P_M=$'\e[35m'; P_0=$'\e[0m'
else
  P_G=""; P_R=""; P_Y=""; P_B=""; P_M=""; P_0=""
fi
prog() { printf '%s\n' "$*" >&2; }

list_hosts() {
  nix eval --json "${REPO}#configHashes" --apply builtins.attrNames 2>/dev/null \
    | tr -d '[]" ' | tr ',' '\n' | grep -v '^$'
}

# host<TAB>targetHost for every machine (single eval).
target_map() {
  nix eval --json "${REPO}#nixosConfigurations" --apply \
    'cfgs: builtins.mapAttrs (n: c: c.config.clan.core.networking.targetHost or "") cfgs' \
    2>/dev/null \
    | { if have_jq; then jq -r 'to_entries[] | "\(.key)\t\(.value)"'
        else tr -d '{}" ' | tr ',' '\n' | sed 's/:/\t/'; fi; }
}

# repo_hash <host>  -> pure config hash the current working tree evaluates to.
repo_hash() {
  nix eval --raw "${REPO}#configHashes.$1" 2>/dev/null
}

# deployed_hash <target>  ("" or local hostname -> read locally)
deployed_hash() {
  local target="$1"
  if [ -z "$target" ] || [ "$target" = "$(hostname)" ] || [ "$target" = "$(hostname).pin" ]; then
    cat /run/current-system/config-hash 2>/dev/null || echo __MISSING__; return 0
  fi
  # Two exit conditions differ: ssh-unreachable vs file-missing. Probe reachability first.
  ssh -n "${SSH_OPTS[@]}" "${SSH_USER}@${target}" \
    'cat /run/current-system/config-hash 2>/dev/null || echo __MISSING__' 2>/dev/null
}

# Emit one line: STATE<TAB>host<TAB>detail. Never exits nonzero (parallel use).
check_one() {
  local host="$1" target="$2" repo dep
  # Probe the deployed side FIRST: a 32s repo eval is wasted on a host we can't
  # reach, so offline hosts cost only the ssh timeout, not an evaluation.
  if ! dep="$(deployed_hash "$target")"; then
    prog "  ${P_B}offline${P_0}  ${host} (${target:-local} unreachable)"
    printf 'offline\t%s\t%s (unreachable)\n' "$host" "${target:-local}"; return 0
  fi
  dep="$(printf '%s' "$dep" | tr -d '[:space:]')"
  prog "  ${P_Y}…eval${P_0}   ${host} (reachable, evaluating config ~30s)"
  repo="$(repo_hash "$host" || true)"
  if [ -z "$repo" ]; then
    prog "  ${P_Y}error${P_0}   ${host} (repo eval failed)"
    printf 'error\t%s\teval failed (repo)\n' "$host"; return 0
  fi
  if [ -z "$dep" ] || [ "$dep" = "__MISSING__" ]; then
    prog "  ${P_M}stale${P_0}   ${host} (no config-hash deployed; redeploy once)"
    printf 'stale\t%s\tno /run/current-system/config-hash (redeploy once); repo=%s\n' "$host" "$repo"
    return 0
  fi
  if [ "$repo" = "$dep" ]; then
    prog "  ${P_G}clean${P_0}   ${host}"
    printf 'clean\t%s\t%s\n' "$host" "$repo"
  else
    prog "  ${P_R}dirty${P_0}   ${host} (repo != deployed)"
    printf 'dirty\t%s\trepo=%s deployed=%s\n' "$host" "$repo" "$dep"
  fi
}

cmd_status() {
  local only="${1:-}"
  local tmp; tmp="$(mktemp -d)"
  target_map > "$tmp/targets"
  if [ -n "$only" ]; then
    grep -q "^${only}"$'\t' "$tmp/targets" || { rm -rf "$tmp"; die "unknown host '${only}' (try: list)"; }
    grep "^${only}"$'\t' "$tmp/targets" > "$tmp/targets.f" && mv "$tmp/targets.f" "$tmp/targets"
  fi
  local n; n="$(grep -c . "$tmp/targets")"
  prog "${P_B}checking ${n} machine(s), up to ${JOBS} in parallel (ssh probe + ~30s eval per reachable host)…${P_0}"
  local running=0 host target
  while IFS=$'\t' read -r host target; do
    [ -n "$host" ] || continue
    check_one "$host" "$target" < /dev/null >> "$tmp/out" &
    running=$((running + 1))
    if [ "$running" -ge "$JOBS" ]; then wait -n 2>/dev/null || wait; running=$((running - 1)); fi
  done < "$tmp/targets"
  wait
  prog ""

  local C_G="" C_R="" C_Y="" C_B="" C_M="" C_0=""
  if [ -t 1 ]; then C_G=$'\e[32m'; C_R=$'\e[31m'; C_Y=$'\e[33m'; C_B=$'\e[90m'; C_M=$'\e[35m'; C_0=$'\e[0m'; fi
  local n_clean=0 n_dirty=0 n_off=0 n_stale=0 n_err=0
  printf '%-14s %-9s %s\n' "MACHINE" "STATE" "DETAIL"
  printf '%-14s %-9s %s\n' "-------" "-----" "------"
  local state h detail col
  while IFS=$'\t' read -r state h detail; do
    case "$state" in
      clean)   col="$C_G"; n_clean=$((n_clean+1)) ;;
      dirty)   col="$C_R"; n_dirty=$((n_dirty+1)) ;;
      offline) col="$C_B"; n_off=$((n_off+1)) ;;
      stale)   col="$C_M"; n_stale=$((n_stale+1)) ;;
      *)       col="$C_Y"; n_err=$((n_err+1)) ;;
    esac
    printf '%-14s %b%-9s%b %s\n' "$h" "$col" "$state" "$C_0" "$detail"
  done < <(sort "$tmp/out")
  echo
  printf 'summary: %bclean=%d%b %bdirty=%d%b %bstale=%d%b %boffline=%d%b%s\n' \
    "$C_G" "$n_clean" "$C_0" "$C_R" "$n_dirty" "$C_0" "$C_M" "$n_stale" "$C_0" \
    "$C_B" "$n_off" "$C_0" "$([ "$n_err" -gt 0 ] && printf ' %serror=%d%s' "$C_Y" "$n_err" "$C_0")"
  local rc=0; { [ "$n_dirty" -eq 0 ] && [ "$n_err" -eq 0 ]; } || rc=1
  rm -rf "$tmp"
  return $rc
}

main() {
  local sub="${1:-}"; shift || true
  case "$sub" in
    list) list_hosts ;;
    hash)
      local host="${1:-}"; [ -n "$host" ] || die "usage: hash <host>"
      repo_hash "$host" || die "eval failed for '${host}'" ;;
    status) cmd_status "${1:-}" ;;
    ""|-h|--help) sed -n '2,44p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' ;;
    *) die "unknown subcommand '$sub' (try --help)" ;;
  esac
}

main "$@"
