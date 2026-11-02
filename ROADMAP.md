# Next improvements

Planned, in this order.

## 1. Resizing windows from inside the edge

**Problem:** Window borders are set to "None". KDE then places the resize area only outside the window's edge, and the rounded corners clip the corners, which is where a resize is usually grabbed.

**Plan:**
- Switch the border size from "None" to "Tiny", a 1–2px border in the window's own color, so edges can be grabbed from inside the window. Confirm the rounded corners still render cleanly with it.
- Optionally add Cmd+right-drag anywhere in a window to resize it. Check for conflicts with apps that use Alt+right-click.

**Check:** resize from every edge and corner in a KDE app, Firefox and VS Code.

## 2. Consistent window button spacing across apps

**Problem:** KDE apps get their title bar buttons from Breeze, while Firefox and VS Code draw their own title bar with different spacing. The 20px rounded corner next to the close button makes the difference stand out.

**Plan:**
- Make Firefox and VS Code use the system title bar so every window gets identical buttons:
  - **Firefox:** enable "Title Bar" in Customize Toolbar.
  - **VS Code:** set `"window.titleBarStyle": "native"`.
- This costs a little height, so if it's too much, keep the apps' own title bars and tune the Breeze button size and corner radius until they line up.

**Check:** compare a KDE app, Firefox and VS Code side by side.

## 3. Bigger search on high-resolution screens

**Problem:** KRunner opens at a fixed size that doesn't grow with display scaling, so it looks small on a 4K screen.

**Plan:**
- Check whether KRunner keeps a larger size after its edges are dragged, and whether that size can be saved in its settings.
- If not, choose between:
  - Overview search (Ctrl+↑, then type), which is large and centered but looks different.
  - a larger font just for KRunner.

  Raising the global scale is a last resort, because it resizes everything else as well.

**Check:** screenshot search on a 4K screen.

## 4. Installer

- **Multi-monitor layouts:** put the dock on the primary screen rather than on screen 0. Test with a rotated (portrait) second monitor.
- **Wallpaper:** decide whether the installer should set one.
- **Fixes from this list:** add each one to the installer.
- **Full test run:** run the complete installer on a fresh system, in a new user account or a virtual machine, then remove the work-in-progress label.
