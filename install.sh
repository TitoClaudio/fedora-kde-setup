#!/usr/bin/env bash
# Fedora KDE setup: Mac-style keys, top bar + dock, glass panels, rounded windows.
# Run as your normal user from a terminal inside a Plasma session: ./install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Application Title Bar widget, pinned to the reviewed commit (v0.10.0)
TITLE_BAR_REPO="https://github.com/antroids/application-title-bar"
TITLE_BAR_COMMIT="54a6666"

# Panel background opacity for the glass theme (Breeze default is 0.85)
PANEL_OPACITY="0.35"

info() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; exit 1; }

check_environment() {
    [[ $EUID -ne 0 ]] || die "Run this as your normal user, not root. It asks for sudo when needed."
    grep -q '^ID=fedora' /etc/os-release || die "This installer is for Fedora."
    command -v plasmashell >/dev/null || die "KDE Plasma is not installed."
    local major
    major=$(plasmashell --version | grep -oE '[0-9]+' | head -1)
    [[ $major -ge 6 ]] || die "Plasma 6 or newer is required."
    command -v qdbus-qt6 >/dev/null || die "qdbus-qt6 is missing (package qt6-qttools)."
    qdbus-qt6 org.kde.plasmashell /PlasmaShell >/dev/null 2>&1 \
        || die "Run this from a terminal inside your Plasma session."
}

backup_configs() {
    local dir="$HOME/kde-setup-backup-$(date +%Y%m%d-%H%M%S)"
    info "Backing up current settings to $dir"
    mkdir -p "$dir"
    local f
    for f in plasma-org.kde.plasma.desktop-appletsrc plasmashellrc kwinrc breezerc \
             krunnerrc kdeglobals kglobalshortcutsrc powerdevilrc plasmarc \
             gtk-3.0/settings.ini gtk-4.0/settings.ini; do
        if [[ -f "$HOME/.config/$f" ]]; then
            mkdir -p "$dir/$(dirname "$f")"
            cp -a "$HOME/.config/$f" "$dir/$f"
        fi
    done
}

# Lists keyboards as "vendor:product<TAB>name", one per hardware ID
list_keyboards() {
    awk '
        /^I:/ { vendor = ""; product = ""
                for (i = 1; i <= NF; i++) {
                    if ($i ~ /^Vendor=/)  vendor  = substr($i, 8)
                    if ($i ~ /^Product=/) product = substr($i, 9)
                } }
        /^N:/ { sub(/^N: Name="/, ""); sub(/"$/, ""); name = $0 }
        /^H:/ { kbd = ($0 ~ /kbd/) }
        /^B: EV=/ { ev = substr($2, 4) }
        /^$/ { if (kbd && ev == "120013" && vendor != "0000" && !seen[vendor ":" product]++)
                   print vendor ":" product "\t" name
               kbd = 0; ev = "" }
    ' /proc/bus/input/devices
}

choose_keyboards() {
    local -a ids names
    local line
    while IFS=$'\t' read -r id name; do
        ids+=("$id"); names+=("$name")
    done < <(list_keyboards)

    echo "Which keyboards should use the Mac layout?" >&2
    local i
    for i in "${!ids[@]}"; do
        printf '  %d) %s  (%s)\n' $((i + 1)) "${names[$i]}" "${ids[$i]}" >&2
    done
    echo "  a) All keyboards, including ones connected later" >&2
    read -rp "Choose numbers separated by spaces, or a: " line

    if [[ $line =~ ^[[:space:]]*[aA][[:space:]]*$ ]]; then
        echo "*"
        return
    fi
    local n picked=""
    for n in $line; do
        [[ $n =~ ^[0-9]+$ ]] && (( n >= 1 && n <= ${#ids[@]} )) \
            || die "Invalid choice: $n"
        picked+="${ids[$((n - 1))]}"$'\n'
    done
    [[ -n $picked ]] || die "No keyboard selected."
    printf '%s' "$picked"
}

install_packages() {
    info "Installing keyd and the rounded corners effect (asks for your password)"
    sudo dnf copr enable -y alternateved/keyd
    sudo dnf copr enable -y matinlotfali/KDE-Rounded-Corners
    sudo dnf install -y keyd kwin-effect-roundcorners git
}

setup_keyd() {
    info "Setting up Mac-style keys"
    local ids
    ids=$(choose_keyboards)

    local conf
    conf=$(mktemp)
    {
        echo "# Mac-style keys: Alt (next to space) = Cmd, Win = Option, Ctrl = Ctrl."
        echo "# Installed by fedora-kde-setup."
        echo "[ids]"
        printf '%s\n' "$ids"
        echo
        cat "$REPO_DIR/keyd/mac-keys.conf"
    } > "$conf"
    keyd check "$conf" >/dev/null || die "keyd rejected the generated config ($conf)."

    sudo install -Dm644 "$conf" /etc/keyd/default.conf
    sudo install -Dm644 "$REPO_DIR/keyd/restart.conf" /etc/systemd/system/keyd.service.d/restart.conf
    rm -f "$conf"
    sudo systemctl daemon-reload
    sudo systemctl enable keyd
    # Restart rather than reload: reloading while a key is held can crash keyd
    sudo systemctl restart keyd
}

apply_kde_settings() {
    info "Applying window, search and power settings"
    local k=kwriteconfig6

    # Window buttons on the left (close, minimize, maximize), centered titles, no borders
    $k --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft "XIA"
    $k --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight ""
    $k --file kwinrc --group org.kde.kdecoration2 --key BorderSize "None"
    $k --file kwinrc --group org.kde.kdecoration2 --key BorderSizeAuto false
    $k --file breezerc --group Windeco --key TitleAlignment "AlignCenterFullWidth"
    $k --file breezerc --group Windeco --key DrawBackgroundGradient false
    $k --file breezerc --group Common --key ShadowSize "ShadowVeryLarge"
    $k --file breezerc --group Common --key ShadowStrength 160

    # Same button layout for GTK apps (Firefox, VS Code)
    local layout="close,minimize,maximize:" f
    for f in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
        $k --file "$f" --group Settings --key gtk-decoration-layout "$layout"
    done
    gsettings set org.gnome.desktop.wm.preferences button-layout "$layout" 2>/dev/null || true

    # Blur, rounded corners (no dark outline), Cmd+Tab shows one icon per app
    $k --file kwinrc --group Plugins --key blurEnabled true
    $k --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled true
    $k --file kwinrc --group Round-Corners --key OutlineThickness 0
    $k --file kwinrc --group Round-Corners --key InactiveOutlineThickness 0
    $k --file kwinrc --group TabBox --key LayoutName big_icons
    $k --file kwinrc --group TabBox --key ApplicationsMode 1

    # Two desktops for Ctrl+Left/Right
    local n
    n=$(kreadconfig6 --file kwinrc --group Desktops --key Number --default 1)
    (( n >= 2 )) || $k --file kwinrc --group Desktops --key Number 2

    # Search (KRunner) in the middle of the screen
    $k --file krunnerrc --group General --key FreeFloating true

    # Never dim, turn off the screen or sleep when idle (screen lock is unchanged)
    $k --file powerdevilrc --group AC --group Display --key DimDisplayWhenIdle false
    $k --file powerdevilrc --group AC --group Display --key TurnOffDisplayWhenIdle false
    $k --file powerdevilrc --group AC --group SuspendAndShutdown --key AutoSuspendAction 0
    qdbus-qt6 org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement \
        org.kde.Solid.PowerManagement.refreshStatus >/dev/null 2>&1 || true

    qdbus-qt6 org.kde.KWin /KWin reconfigure
    qdbus-qt6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect kwin4_effect_shapecorners >/dev/null || true
}

install_glass_theme() {
    info "Creating the Breeze Dark Glass theme"
    local src=/usr/share/plasma/desktoptheme
    local t="$HOME/.local/share/plasma/desktoptheme/breeze-dark-glass"
    mkdir -p "$t/translucent/widgets"
    cp "$src/breeze-dark/colors" "$t/colors"
    cat > "$t/metadata.json" <<'EOF'
{
    "KPlugin": {
        "Authors": [{ "Name": "fedora-kde-setup (based on KDE Breeze Dark)" }],
        "Description": "Breeze Dark with more translucent, glassy panels",
        "Id": "breeze-dark-glass",
        "License": "LGPL",
        "Name": "Breeze Dark Glass",
        "Version": "1.0"
    },
    "X-Plasma-API": "5.0"
}
EOF
    cat > "$t/plasmarc" <<'EOF'
[ContrastEffect]
enabled=true
contrast=0.6
intensity=1.0
saturation=1.8

[AdaptiveTransparency]
enabled=true
EOF
    local svg="$src/default/translucent/widgets/panel-background.svgz"
    zcat "$svg" | grep -q 'opacity:0\.85' \
        || warn "Breeze's panel image changed in this Plasma version; the panels may not be more transparent."
    zcat "$svg" | sed "s/opacity:0\.85/opacity:$PANEL_OPACITY/g" | gzip -9 > "$t/translucent/widgets/panel-background.svgz"

    rm -f "$HOME"/.cache/plasma_theme_breeze-dark-glass* "$HOME"/.cache/plasma-svgelements-breeze-dark-glass*
    plasma-apply-colorscheme BreezeDark >/dev/null
    plasma-apply-desktoptheme breeze-dark-glass >/dev/null
}

install_title_widget() {
    info "Installing the app name widget (Application Title Bar $TITLE_BAR_COMMIT)"
    local tmp
    tmp=$(mktemp -d)
    git clone -q "$TITLE_BAR_REPO" "$tmp/src"
    git -C "$tmp/src" checkout -q "$TITLE_BAR_COMMIT"
    kpackagetool6 -t Plasma/Applet -i "$tmp/src/package" >/dev/null 2>&1 \
        || kpackagetool6 -t Plasma/Applet -u "$tmp/src/package" >/dev/null
    rm -rf "$tmp"
}

setup_panels() {
    info "Building the top bar and dock"
    local ids id
    ids=$(qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
        "$(cat "$REPO_DIR/plasma/panels.js")")
    # Always translucent, even when a window is maximized
    for id in $ids; do
        kwriteconfig6 --file plasmashellrc --group PlasmaViews --group "Panel $id" --key panelOpacity 2
    done
    systemctl --user restart plasma-plasmashell
}

main() {
    check_environment
    echo "This will replace your panels and change window, keyboard and theme settings."
    read -rp "Continue? [y/N] " answer
    [[ $answer =~ ^[yY] ]] || exit 0

    backup_configs
    install_packages
    setup_keyd
    apply_kde_settings
    install_glass_theme
    install_title_widget
    setup_panels

    info "Done. Log out and back in so every app picks up the new settings."
}

main "$@"
