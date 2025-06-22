import json
import sys
from pathlib import Path


def load_json(file_path: Path) -> dict[str, any]:
    try:
        with file_path.open("r") as file:
            return json.load(file)
    except FileNotFoundError:
        return {}


def save_json(file_path: Path, data: dict[str, any]) -> None:
    with file_path.open("w") as file:
        json.dump(data, file, indent=4)


def update_json(file_path: Path, updates: dict[str, any]) -> None:
    data = load_json(file_path)
    data.update(updates)
    save_json(file_path, data)


def config_location() -> str:
    config_file = "shared_preferences.json"
    config_directory = ".local/share/org.localsend.localsend_app"
    config_path = Path.home() / Path(config_directory) / Path(config_file)
    return config_path


def ensure_config_directory() -> None:
    config_directory = Path(config_location()).parent
    config_directory.mkdir(parents=True, exist_ok=True)


def load_config() -> dict[str, any]:
    return load_json(config_location())


def save_config(data: dict[str, any]) -> None:
    save_json(config_location(), data)


def update_username(username: str, data: dict[str, any]) -> dict[str, any]:
    data["flutter.ls_alias"] = username
    return data


def main(argv: list[str]) -> None:
    try:
        display_name = argv[1]
    except IndexError:
        # This is not an error, just don't update the name
        print("No display name provided.")
        sys.exit(0)

    ensure_config_directory()
    updated_data = update_username(display_name, load_config())
    save_config(updated_data)


if __name__ == "__main__":
    main(sys.argv[:2])
