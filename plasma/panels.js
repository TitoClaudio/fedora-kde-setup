// Plasma desktop script: replaces all panels with a top bar on every screen
// and a floating dock on the primary screen. Prints "<id>" for each new panel
// so the installer can set their opacity. The installer prepends three variables:
// PRIMARY (connector name of the primary screen), WALLPAPER (file path, or "")
// and VSCODE_APP (VS Code's desktop file: the RPM's or the Flatpak's).

panels().forEach(function(p) { p.remove(); });

function topBar(screen) {
    var p = new Panel("org.kde.panel");
    p.screen = screen;
    p.location = "top";
    p.height = 28;
    p.floating = false;
    p.lengthMode = "fill";
    p.hiding = "none";

    var launcher = p.addWidget("org.kde.plasma.kickoff");
    launcher.currentConfigGroup = ["General"];
    launcher.writeConfig("icon", "start-here-kde-symbolic");

    // Bold name of the focused app, no buttons or icon, no mouse actions
    var title = p.addWidget("com.github.antroids.application-title-bar");
    title.currentConfigGroup = ["Appearance"];
    title.writeConfig("widgetElements", "windowTitle");
    title.writeConfig("windowTitleSource", 0);
    title.writeConfig("windowTitleSourceMaximized", 0);
    title.writeConfig("windowTitleFontBold", true);
    title.writeConfig("windowTitleFontSize", 10);
    title.writeConfig("windowTitleUndefined", "Desktop");
    title.writeConfig("windowTitleMarginsLeft", 4);
    title.writeConfig("windowTitleMarginsRight", 4);
    title.currentConfigGroup = ["Behavior"];
    title.writeConfig("windowTitleDragEnabled", false);
    ["LeftDrag", "LeftDoubleClick", "MiddleClick", "WheelUp", "WheelDown"].forEach(function(a) {
        title.writeConfig("widgetMouseArea" + a + "Action", "");
    });

    p.addWidget("org.kde.plasma.panelspacer");
    p.addWidget("org.kde.plasma.systemtray");

    var clock = p.addWidget("org.kde.plasma.digitalclock");
    clock.currentConfigGroup = ["Appearance"];
    clock.writeConfig("showDate", true);
    clock.writeConfig("dateDisplayFormat", "BesideTime");
    clock.writeConfig("dateFormat", "custom");
    clock.writeConfig("customDateFormat", "ddd d MMM");
    clock.writeConfig("autoFontAndSize", true);
    return p;
}

// Invisible panel under the dock. The dock is "windows go below" so it stays
// floating next to maximized windows, but that mode reserves no space: this
// panel reserves it instead (dock + its floating gap + a small margin), so
// windows maximize with their normal animation and stop above the dock.
function dockSpace(screen) {
    var p = new Panel("org.kde.panel");
    p.screen = screen;
    p.location = "bottom";
    p.height = 74;
    p.floating = false;
    p.lengthMode = "fill";
    p.hiding = "none";
    return p;
}

function dock(screen) {
    var p = new Panel("org.kde.panel");
    p.screen = screen;
    p.location = "bottom";
    p.height = 56;
    p.floating = true;
    p.lengthMode = "fit";
    p.alignment = "center";
    p.hiding = "windowsgobelow";

    var tasks = p.addWidget("org.kde.plasma.icontasks");
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("showOnlyCurrentScreen", false);
    tasks.writeConfig("indicateAudioStreams", true);
    tasks.writeConfig("launchers", [
        "applications:systemsettings.desktop",
        "applications:org.kde.discover.desktop",
        "preferred://filemanager",
        "preferred://browser",
        "applications:" + VSCODE_APP,
        "applications:org.kde.konsole.desktop",
        "applications:org.kde.plasma-systemmonitor.desktop"
    ].join(","));

    p.addWidget("org.kde.plasma.marginsseparator");
    p.addWidget("org.kde.plasma.trash");
    return p;
}

// Plasma numbers the primary screen 0 unless it can be told by connector
var main = PRIMARY ? screenForConnector(PRIMARY) : 0;
if (main < 0) main = 0;

// Same wallpaper on every screen
if (WALLPAPER) {
    desktops().forEach(function(d) {
        d.wallpaperPlugin = "org.kde.image";
        d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
        d.writeConfig("Image", "file://" + WALLPAPER);
    });
}

var ids = [];
for (var i = 0; i < screenCount; i++) {
    ids.push(topBar(i).id);
}
ids.push(dockSpace(main).id);
ids.push(dock(main).id);
print(ids.join(" "));
