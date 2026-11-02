// Plasma desktop script: replaces all panels with a top bar on every screen
// and a floating dock on the primary screen. Prints "<id>" for each new panel
// so the installer can set their opacity.

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

function dock(screen) {
    var p = new Panel("org.kde.panel");
    p.screen = screen;
    p.location = "bottom";
    p.height = 56;
    p.floating = true;
    p.lengthMode = "fit";
    p.alignment = "center";
    p.hiding = "dodgewindows";

    var tasks = p.addWidget("org.kde.plasma.icontasks");
    tasks.currentConfigGroup = ["General"];
    tasks.writeConfig("showOnlyCurrentScreen", false);
    tasks.writeConfig("indicateAudioStreams", true);
    tasks.writeConfig("launchers", [
        "applications:systemsettings.desktop",
        "applications:org.kde.discover.desktop",
        "preferred://filemanager",
        "preferred://browser",
        "applications:com.microsoft.VSCode.desktop"
    ].join(","));

    p.addWidget("org.kde.plasma.marginsseparator");
    p.addWidget("org.kde.plasma.trash");
    return p;
}

var ids = [];
for (var i = 0; i < screenCount; i++) {
    ids.push(topBar(i).id);
}
ids.push(dock(0).id);
print(ids.join(" "));
