#!/usr/bin/env python3
"""
authelia-users-gen: Generate Authelia users.yaml from config with secret file references.

Usage: authelia-users-gen <config.json> <output.yaml>

For any field, you can use either:
  - Direct value: "email": "user@example.com"
  - File reference: "emailFile": "/run/secrets/email" (reads value from file)

The *File suffix convention works for any field, allowing secrets to be kept
out of the Nix store.

Example config.json:
{
  "users": {
    "pinpox": {
      "displayname": "Pablo",
      "email": "pinpox@example.com",
      "groups": ["admins"],
      "passwordFile": "/run/secrets/pinpox-hash"
    }
  }
}
"""

import json
import os
import sys
from pathlib import Path


def resolve_user_fields(username: str, user: dict) -> dict:
    """
    Resolve user fields, handling *File references.

    For each *File field, read the value from that file and store it
    under the base field name. Other fields are passed through as-is.
    """
    result = {}
    file_fields = {k: v for k, v in user.items() if k.endswith("File") and v is not None}
    base_field_names = {k[:-4] for k in file_fields.keys()}  # Strip "File" suffix

    for key, value in user.items():
        if key.endswith("File"):
            # Handle *File field - read from file
            if value is not None:
                base_name = key[:-4]
                file_path = Path(value)
                if not file_path.exists():
                    print(f"Error: {file_path} not found for field '{base_name}'", file=sys.stderr)
                    sys.exit(1)
                result[base_name] = file_path.read_text().strip()
        elif key in base_field_names:
            # Skip - the *File variant takes precedence
            pass
        elif value is not None:
            # Pass through as-is
            result[key] = value

    return result


def main() -> None:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <config.json> <output.yaml>", file=sys.stderr)
        sys.exit(1)

    config_path, output_path = sys.argv[1], sys.argv[2]
    config = json.loads(Path(config_path).read_text())

    users = {}
    for username, user in config["users"].items():
        users[username] = resolve_user_fields(username, user)

    # Write with 0600 permissions from the start
    fd = os.open(output_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump({"users": users}, f, indent=2)


if __name__ == "__main__":
    main()
