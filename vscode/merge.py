#!/usr/bin/env python3
"""Merge the exported Cursor settings and keybindings into a VS Code user folder.

    python3 vscode/merge.py ~/.config/Code/User

Settings already in VS Code are kept; where both set the same one, Cursor's
value wins. Cursor keybindings are added unless VS Code already has them.
"""
import sys
from pathlib import Path

from jsonc import load_jsonc, write_json

SRC = Path(__file__).resolve().parent


def load_existing(path, default):
    try:
        return load_jsonc(path, default)
    except ValueError:
        print(f"  ! Couldn't read {path}, replacing it (the backup has the old one).")
        return default


def main():
    dest = Path(sys.argv[1]).expanduser()
    dest.mkdir(parents=True, exist_ok=True)

    current = load_existing(dest / "settings.json", {})
    merged = {**current, **load_jsonc(SRC / "settings.json", {})}
    if merged != current or not (dest / "settings.json").exists():
        write_json(dest / "settings.json", merged)

    current = load_existing(dest / "keybindings.json", [])
    new = [b for b in load_jsonc(SRC / "keybindings.json", []) if b not in current]
    if new:
        write_json(dest / "keybindings.json", current + new)


if __name__ == "__main__":
    main()
