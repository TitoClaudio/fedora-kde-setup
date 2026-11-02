# fedora-kde-setup

One-command setup for Fedora KDE Plasma 6 that brings over the parts of the macOS layout worth keeping: Cmd-key shortcuts, a top bar showing the focused app, a floating dock, glassy panels and rounded windows. It uses no Apple logos, names or icons, just KDE's own Breeze look, rearranged.

## Install

On Fedora KDE, from a terminal inside your Plasma session:

```bash
git clone https://github.com/TitoClaudio/fedora-kde-setup
cd fedora-kde-setup
./install.sh
```

The script asks for your sudo password once to install packages. It also asks which keyboards should get the Mac layout. When it finishes, log out and back in.

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
- **Floating dock on the main screen:** sized to its icons, with a trash can, and hides when a window covers it.
- **Breeze Dark Glass:** a local copy of Breeze Dark with more see-through, blurred panels. It's generated from your installed Breeze files, so nothing is downloaded.
- **Rounded windows:** the [KDE-Rounded-Corners](https://github.com/matinlotfali/KDE-Rounded-Corners) effect with squircle corners and no dark outline.
- **Windows:** close / minimize / maximize on the left, including GTK apps like Firefox and VS Code, centered titles and no borders.
- **Search** opens in the middle of the screen.
- **App switcher** shows one large icon per app.
- **Two virtual desktops.**
- **No idle dimming, screen-off or sleep.** The 5-minute screen lock is left as is.

## Undo

- **Keys:** `sudo systemctl disable --now keyd` gives you a normal keyboard immediately.
- **Theme:** System Settings → Colors & Themes → Plasma Style → Breeze Dark.
- **Rounded corners:** System Settings → Window Management → Desktop Effects → untick Rounded Corners.
- **Everything else:** copy the files from your `~/kde-setup-backup-<date>/` folder back into `~/.config/`, then log out and back in.

## Requirements

Fedora with KDE Plasma 6 on Wayland. Tested on Fedora 44 with Plasma 6.8.
