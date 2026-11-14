// KWin script: hides the empty panel that plasma/panels.js adds under the dock
// to reserve space for it. It is the only panel of this height.

const RESERVE_HEIGHT = 74;

function hideIfReserve(w) {
    if (!w.dock) return;
    const apply = () => {
        if (w.frameGeometry.height === RESERVE_HEIGHT) w.opacity = 0;
    };
    apply();
    w.frameGeometryChanged.connect(apply);
}

workspace.windowList().forEach(hideIfReserve);
workspace.windowAdded.connect(hideIfReserve);
