#!/usr/bin/env python3
"""
nix-to-config: Transform Nix JSON with *File references into config files.

Usage: nix-to-config <input.json> <output.json>

Recursively walks the JSON structure. For any key ending in "File":
- Reads the value as a file path
- Stores the file contents under the key without "File" suffix
- Removes the original *File key

Example:
  Input:  { "users": { "pinpox": { "passwordFile": "/run/secrets/hash" } } }
  Output: { "users": { "pinpox": { "password": "<contents of /run/secrets/hash>" } } }
"""

import json
import os
import sys
from pathlib import Path


def get_file_key_info(key):
    """Check if key is a file reference and return (is_file_key, base_name)."""
    if key.endswith("File"):
        return True, key[:-4]  # passwordFile -> password
    elif key.endswith("_file"):
        return True, key[:-5]  # client_secret_file -> client_secret
    return False, None


def resolve_file_refs(obj):
    """Recursively resolve *File and *_file references in any JSON structure."""
    if isinstance(obj, dict):
        result = {}
        # Collect base names of all file keys
        file_base_names = set()
        for k, v in obj.items():
            is_file_key, base_name = get_file_key_info(k)
            if is_file_key and v is not None:
                file_base_names.add(base_name)

        for key, value in obj.items():
            is_file_key, base_name = get_file_key_info(key)
            if is_file_key and value is not None:
                # Read file, store under base name
                file_path = Path(value)
                if not file_path.exists():
                    print(f"Error: {file_path} not found for field '{base_name}'", file=sys.stderr)
                    sys.exit(1)
                result[base_name] = file_path.read_text().strip()
            elif key in file_base_names:
                # Skip - *File/*_file variant takes precedence
                pass
            elif value is not None:
                # Recurse
                result[key] = resolve_file_refs(value)
        return result
    elif isinstance(obj, list):
        return [resolve_file_refs(item) for item in obj]
    else:
        return obj


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <input.json> <output.json>", file=sys.stderr)
        sys.exit(1)

    input_path, output_path = sys.argv[1], sys.argv[2]
    data = json.loads(Path(input_path).read_text())

    result = resolve_file_refs(data)

    # Write with 0600 permissions
    fd = os.open(output_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        json.dump(result, indent=2, fp=f)


if __name__ == "__main__":
    main()
