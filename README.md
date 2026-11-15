# fedora-kde-setup

> **Work in progress.** The installer hasn't been run end to end on a fresh system yet, so things may change or break. Check the result before relying on it.

One-command setup for Fedora KDE Plasma 6 that brings over the parts of the macOS layout worth keeping: Cmd-key shortcuts, a top bar showing the focused app, a floating dock, glassy panels and rounded windows. It also installs VS Code with your Cursor settings and extensions. It uses no Apple logos, names or icons, just KDE's own Breeze look, rearranged.

## Install

On Fedora KDE, from a terminal inside your Plasma session:

```bash
git clone https://github.com/TitoClaudio/fedora-kde-setup
cd fedora-kde-setup
./install.sh
```

The script asks for your sudo password once to install packages, including VS Code. It also asks which keyboards should get the Mac layout. When it finishes, log out and back in.

Your current settings are backed up to `~/kde-setup-backup-<date>/` first.

## What it changes

### Keyboard

[keyd](https://github.com/rvaiya/keyd) is installed from COPR and translates keys at the system level, so this works the same in every app.

| Physical key | Acts as |
|---|---|
| Alt (next to space) | Cmd |
| Win | Option |
| Ctrl | Ctrl |

| Shortcut | Does |
|---|---|
| Cmd+C / V / X / Z / A / S / T / W / Q / F… | same as on a Mac |
| Cmd+Space or F4 | search (KRunner) |
| Cmd+Tab, Cmd+\` | switch apps, cycle an app's windows |
| Cmd+← / → / ↑ / ↓ | start/end of line, top/bottom (add Shift to select) |
| Cmd+Backspace | delete to start of line |
| Option+← / → / Backspace | move or delete by word |
| Cmd+[ / ] | back / forward |
| Cmd+Shift+[ / ] | previous / next tab |
| Cmd+1…9 | jump to tab |
| Cmd+H, Cmd+M | minimize |
| Cmd+Shift+3 / 4 / 5 | screenshot: full screen / region / Spectacle |
| Cmd+Ctrl+Q | lock screen |
| Cmd+Option+Esc | force quit (click the window) |
| Ctrl+↑ | Overview (like Mission Control) |
| Ctrl+← / → | switch desktop |

**Game mode:** Cmd+Ctrl+G switches back to standard PC keys, and Ctrl+Alt+G returns to Mac mode. A reboot always starts in Mac mode.

### Desktop

- **Top bar on every screen:** launcher, the bold name of the focused app, system tray and clock. The app name comes from the [Application Title Bar](https://github.com/antroids/application-title-bar) widget, pinned to a reviewed commit.
- **Floating dock on the primary screen:** sized to its icons, with Settings, Discover, Files, browser, VS Code, Konsole and System Monitor pinned, and a trash can. It stays visible and floating, and maximized windows stop above it.
- **Breeze Dark Glass:** a local copy of Breeze Dark with more see-through, blurred panels. It's generated from your installed Breeze files, so nothing is downloaded.
- **Rounded windows:** the [KDE-Rounded-Corners](https://github.com/matinlotfali/KDE-Rounded-Corners) effect with squircle corners and no dark outline.
- **Windows:** centered titles and a thin border you can resize from. Buttons stay in the default KDE position.
- **Wallpaper:** the bundled wallpaper is set on every screen.
- **Search** opens in the middle of the screen, 1.5x bigger. To change the size, edit `QT_SCALE_FACTOR` in `~/.config/systemd/user/plasma-krunner.service.d/scale.conf`.
- **App switcher** shows one large icon per app.
- **Two virtual desktops.**
- **No idle dimming, screen-off or sleep.** The 5-minute screen lock is left as is.

### VS Code

VS Code is installed from Microsoft's repository and set up with the settings, keybindings, snippets and extensions exported from Cursor into [`vscode/`](vscode/).

If VS Code is already installed, it's kept and nothing is reinstalled:

- Settings are merged: yours stay, and where both set the same one, Cursor's value wins. Comments in your `settings.json` are lost, but the original is in the backup folder.
- Cursor's keybindings and extensions are added next to yours.
- If you only have the Flatpak from Flathub, that one is set up and pinned in the dock instead of installing a second copy. If you have both, the Microsoft one is set up and the Flatpak is left as is.

What changes on the way from Cursor:

- Cursor's own builds of Microsoft extensions are replaced with the originals: Cursor Pyright with Pylance, and Remote SSH and Dev Containers with Microsoft's.
- Cursor-only settings, shortcuts and extensions are left out, and so are extensions disabled in Cursor.
- Cmd in shortcuts becomes Ctrl, which is what the Cmd key sends here.

To update the copy, run this on the computer with Cursor, then commit the changed files:

```bash
python3 vscode/export-from-cursor.py
```

It exports the profile that new Cursor windows open with. Add `--profile NAME` to export a different one. The files are plain text in this repository, so check them for tokens or private paths before you push.

## Undo

- **Keys:** `sudo systemctl disable --now keyd` gives you a normal keyboard immediately.
- **Theme:** System Settings → Colors & Themes → Plasma Style → Breeze Dark.
- **Rounded corners:** System Settings → Window Management → Desktop Effects → untick Rounded Corners.
- **VS Code:** your previous `settings.json` and `keybindings.json` are in `~/kde-setup-backup-<date>/Code/User/` (or `vscode-flatpak/` for the Flatpak). Remove extensions with `code --uninstall-extension <id>`.
- **Everything else:** copy the files from your `~/kde-setup-backup-<date>/` folder back into `~/.config/`, then log out and back in.

## Requirements

Fedora with KDE Plasma 6 on Wayland. Tested on Fedora 44 with Plasma 6.8.
