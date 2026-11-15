#!/usr/bin/env python3
"""Export your Cursor setup so install.sh can apply it to VS Code on Fedora.

Run this on the computer where Cursor is set up (macOS or Linux):

    python3 vscode/export-from-cursor.py [--profile NAME]

It reads the Cursor profile that new windows open with (or the one named with
--profile) and writes Linux-ready files next to this script:

    settings.json     Cursor-only settings removed
    keybindings.json  Cursor-only commands removed, Cmd becomes Ctrl
    snippets/         copied as is
    extensions.txt    Cursor's own forks swapped for the VS Code originals,
                      disabled and built-in extensions left out
"""
import argparse
import json
import platform
import shutil
import sqlite3
import sys
from pathlib import Path

from jsonc import load_jsonc, write_json

OUT = Path(__file__).resolve().parent

# Cursor ships its own builds of these Microsoft extensions
EXTENSION_MAP = {
    "anysphere.cursorpyright": "ms-python.vscode-pylance",
    "anysphere.remote-ssh": "ms-vscode-remote.remote-ssh",
    "anysphere.remote-containers": "ms-vscode-remote.remote-containers",
    "anysphere.cpptools": "ms-vscode.cpptools",
    "anysphere.csharp": "ms-dotnettools.csharp",
}

CURSOR_SETTING_PREFIXES = ("cursor", "composer.", "anysphere.")
CURSOR_SETTINGS = {"window.newWindowProfile"}  # names a Cursor profile
CURSOR_COMMAND_PREFIXES = ("composer", "aichat.", "aipopup.", "cursorai.", "cursor.", "anysphere.")

# Keys keyd turns into something else when pressed with Cmd (keyd/mac-keys.conf)
KEYD_CMD_KEYS = {"c", "v", "x", "h", "m", "left", "right", "up", "down", "backspace",
                 "[", "]", "tab", "`", "space"} | set("123456789")


def cursor_paths():
    home = Path.home()
    if platform.system() == "Darwin":
        user = home / "Library/Application Support/Cursor/User"
    else:
        user = home / ".config/Cursor/User"
    return user, home / ".cursor/extensions"


def find_profile(user, name):
    """Returns (profile dir, display name, useDefaultFlags)."""
    if name is None:
        name = load_jsonc(user / "settings.json", {}).get("window.newWindowProfile")
    if not name or name == "Default":
        return user, "Default", {}
    storage = load_jsonc(user / "globalStorage/storage.json", {})
    for p in storage.get("userDataProfiles") or []:
        if p.get("name") == name:
            return user / "profiles" / p["location"], name, p.get("useDefaultFlags") or {}
    known = ", ".join(p.get("name", "?") for p in storage.get("userDataProfiles") or [])
    sys.exit(f"No Cursor profile named {name!r}. Profiles: Default{', ' + known if known else ''}")


def disabled_extensions(state_db):
    if not state_db.is_file():
        return set()
    try:
        con = sqlite3.connect(state_db.resolve().as_uri() + "?mode=ro", uri=True)
        row = con.execute("SELECT value FROM ItemTable WHERE key = 'extensionsIdentifiers/disabled'").fetchone()
        con.close()
    except sqlite3.Error as e:
        print(f"  ! Couldn't read disabled extensions ({e}); including all of them.")
        return set()
    return {e["id"].lower() for e in json.loads(row[0])} if row else set()


def export_settings(src):
    settings = load_jsonc(src / "settings.json", {})
    dropped = [k for k in settings
               if k in CURSOR_SETTINGS or k.lower().startswith(CURSOR_SETTING_PREFIXES)]
    for k in dropped:
        del settings[k]
    write_json(OUT / "settings.json", settings)
    print(f"Settings: {len(settings)} kept" + (f", dropped Cursor-only {', '.join(dropped)}" if dropped else ""))


def linux_key(key):
    """Mac 'cmd+k cmd+s' -> 'ctrl+k ctrl+s'. Returns (key, keyd-remapped parts)."""
    chords, remapped = [], []
    for chord in key.split():
        *mods, last = chord.split("+")
        had_cmd = "cmd" in mods
        mods = list(dict.fromkeys("ctrl" if m == "cmd" else m for m in mods))
        if had_cmd and last.lower() in KEYD_CMD_KEYS:
            remapped.append(chord)
        chords.append("+".join(mods + [last]))
    return " ".join(chords), remapped


def export_keybindings(src):
    bindings = load_jsonc(src / "keybindings.json", [])
    kept, dropped = [], []
    for b in bindings:
        command = b.get("command", "").lstrip("-")
        if command.startswith(CURSOR_COMMAND_PREFIXES):
            dropped.append(f"{b.get('key')} ({command})")
            continue
        b["key"], remapped = linux_key(b.get("key", ""))
        for chord in remapped:
            print(f"  ! {chord} -> {command}: keyd sends a different key for this on Fedora, check it there.")
        kept.append(b)
    write_json(OUT / "keybindings.json", kept)
    print(f"Keybindings: {len(kept)} kept" + (f", dropped Cursor-only {', '.join(dropped)}" if dropped else ""))


def export_snippets(src):
    out = OUT / "snippets"
    shutil.rmtree(out, ignore_errors=True)
    files = sorted(p for p in (src / "snippets").glob("*") if p.is_file())
    if files:
        out.mkdir()
        for f in files:
            shutil.copy2(f, out / f.name)
    print(f"Snippets: {len(files)} file(s)")


def export_extensions(user, ext_dir, src, ext_src):
    if ext_src == user:
        installed = load_jsonc(ext_dir / "extensions.json", [])
    else:
        installed = load_jsonc(ext_src / "extensions.json", [])
        # Extensions installed for all profiles live in the default list
        installed += [e for e in load_jsonc(ext_dir / "extensions.json", [])
                      if (e.get("metadata") or {}).get("isApplicationScoped")]
    disabled = disabled_extensions(src / "globalStorage/state.vscdb")

    ids, notes = set(), []
    for e in installed:
        ext = e["identifier"]["id"].lower()
        if (e.get("metadata") or {}).get("isBuiltin"):
            continue
        if ext in disabled:
            notes.append(f"{ext} (disabled in Cursor)")
        elif ext in EXTENSION_MAP:
            ids.add(EXTENSION_MAP[ext])
            notes.append(f"{ext} -> {EXTENSION_MAP[ext]}")
        elif ext.startswith("anysphere."):
            notes.append(f"{ext} (Cursor only)")
        else:
            ids.add(ext)
    (OUT / "extensions.txt").write_text("".join(f"{i}\n" for i in sorted(ids)), encoding="utf-8")
    print(f"Extensions: {len(ids)}")
    for n in sorted(set(notes)):
        print(f"  - {n}")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    parser.add_argument("--profile", help="Cursor profile to export (default: the one new windows open with)")
    args = parser.parse_args()

    user, ext_dir = cursor_paths()
    if not user.is_dir():
        sys.exit(f"Cursor settings not found at {user}")
    profile, name, use_default = find_profile(user, args.profile)
    print(f"Exporting Cursor profile {name!r} to {OUT}")

    pick = lambda part: user if use_default.get(part) else profile
    export_settings(pick("settings"))
    export_keybindings(pick("keybindings"))
    export_snippets(pick("snippets"))
    export_extensions(user, ext_dir, profile, pick("extensions"))
    print("Review the files before committing them.")


if __name__ == "__main__":
    main()
