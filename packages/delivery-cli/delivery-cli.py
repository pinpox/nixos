#!/usr/bin/env python3
"""Track deliveries via the 17track API."""

import argparse
import json
import os
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

API_BASE = "https://api.17track.net/track/v2.2"
STATE_FILE = Path(os.environ.get("DELIVERY_STATE_FILE", "deliveries.json"))

CARRIERS = {
    "dhl": 7041,
    "dhl-express": 100001,
    "dhl-parcel": 100047,
    "deutsche-post": 7044,
    "dpd": 100071,
    "hermes": 100031,
    "gls": 100005,
    "ups": 100002,
    "fedex": 100003,
    "amazon": 100143,
}

STATUS_NAMES = {
    0: "In Transit",
    1: "Delivered",
    2: "Exception",
    3: "Returned",
    4: "Expired",
    5: "Pending",
    6: "Info Received",
    7: "Available for Pickup",
    8: "Out for Delivery",
}


def api_key():
    key = os.environ.get("TRACK17_API_KEY", "")
    if not key:
        print("error: TRACK17_API_KEY not set", file=sys.stderr)
        sys.exit(1)
    return key


def api_post(endpoint, body):
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        f"{API_BASE}/{endpoint}",
        data=data,
        headers={"17token": api_key(), "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def load_state():
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return []


def save_state(state):
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2) + "\n")


def cmd_add(args):
    carrier_code = CARRIERS.get(args.carrier)
    if carrier_code is None:
        print(f"error: unknown carrier '{args.carrier}'", file=sys.stderr)
        print(f"available: {', '.join(sorted(CARRIERS))}", file=sys.stderr)
        sys.exit(1)

    result = api_post("register", [{"number": args.number, "carrier": carrier_code}])
    rejected = result.get("data", {}).get("rejected", [])
    if rejected:
        err = rejected[0].get("error", {}).get("message", "unknown error")
        print(f"error: {err}", file=sys.stderr)
        sys.exit(1)

    state = load_state()
    # Don't add duplicates.
    if any(d["number"] == args.number for d in state):
        print(f"already tracking {args.number}")
        return

    state.append({
        "number": args.number,
        "carrier": args.carrier,
        "carrier_code": carrier_code,
        "description": args.description or "",
        "added": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "last_status": "",
        "last_event": "",
        "last_checked": "",
    })
    save_state(state)
    print(f"registered {args.number} ({args.carrier})")


def cmd_remove(args):
    state = load_state()
    entry = next((d for d in state if d["number"] == args.number), None)
    if not entry:
        print(f"not tracking {args.number}", file=sys.stderr)
        sys.exit(1)

    api_post("deletetrack", [{"number": args.number}])
    state = [d for d in state if d["number"] != args.number]
    save_state(state)
    print(f"removed {args.number}")


def cmd_status(args):
    state = load_state()
    if not state:
        print("no deliveries tracked")
        return

    for d in state:
        status = d.get("last_status") or "unknown"
        event = d.get("last_event") or "no updates yet"
        desc = d.get("description")
        label = f"{d['number']} ({d['carrier']})"
        if desc:
            label += f" — {desc}"
        print(f"{label}")
        print(f"  status: {status}")
        print(f"  last:   {event}")
        print()


def cmd_check(args):
    state = load_state()
    if not state:
        print("no deliveries tracked")
        return

    numbers = [{"number": d["number"]} for d in state]
    result = api_post("gettrackinfo", numbers)

    now = datetime.now(timezone.utc).isoformat()
    changes = []

    for item in result.get("data", {}).get("accepted", []):
        number = item.get("number", "")
        entry = next((d for d in state if d["number"] == number), None)
        if not entry:
            continue

        track = item.get("track", {})
        status_code = track.get("e", -1)
        status_name = STATUS_NAMES.get(status_code, f"unknown ({status_code})")

        events = track.get("z0", {}).get("z", [])
        last_event = events[0].get("z", "") if events else ""

        old_status = entry.get("last_status", "")
        old_event = entry.get("last_event", "")

        if status_name != old_status or last_event != old_event:
            changes.append({
                "number": number,
                "description": entry.get("description", ""),
                "old_status": old_status,
                "new_status": status_name,
                "event": last_event,
            })

        entry["last_status"] = status_name
        entry["last_event"] = last_event
        entry["last_checked"] = now

    save_state(state)

    if not changes:
        print("no updates")
        return

    for c in changes:
        desc = c["description"]
        label = c["number"]
        if desc:
            label += f" ({desc})"
        print(f"{label}: {c['old_status'] or 'new'} -> {c['new_status']}")
        if c["event"]:
            print(f"  {c['event']}")


def main():
    parser = argparse.ArgumentParser(description="Track deliveries via 17track")
    sub = parser.add_subparsers(dest="command", required=True)

    p_add = sub.add_parser("add", help="Register a new tracking number")
    p_add.add_argument("number", help="Tracking number")
    p_add.add_argument("--carrier", "-c", required=True, choices=sorted(CARRIERS),
                        help="Carrier name")
    p_add.add_argument("--description", "-d", default="", help="Package description")
    p_add.set_defaults(func=cmd_add)

    p_remove = sub.add_parser("remove", help="Stop tracking a number")
    p_remove.add_argument("number", help="Tracking number")
    p_remove.set_defaults(func=cmd_remove)

    p_status = sub.add_parser("status", help="Show all tracked deliveries")
    p_status.set_defaults(func=cmd_status)

    p_check = sub.add_parser("check", help="Check for updates from 17track")
    p_check.set_defaults(func=cmd_check)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
