# Next improvements

Planned, in this order.

## 1. Bigger search on high-resolution screens

**Problem:** KRunner opens at a fixed size that doesn't grow with display scaling, so it looks small on a 4K screen.

**Plan:**
- Check whether KRunner keeps a larger size after its edges are dragged, and whether that size can be saved in its settings.
- If not, choose between:
  - Overview search (Ctrl+↑, then type), which is large and centered but looks different.
  - a larger font just for KRunner.

  Raising the global scale is a last resort, because it resizes everything else as well.

**Check:** screenshot search on a 4K screen.

## 2. Installer

- **Multi-monitor layouts:** put the dock on the primary screen rather than on screen 0. Test with a rotated (portrait) second monitor.
- **Wallpaper:** decide whether the installer should set one.
- **Fixes from this list:** add each one to the installer.
- **Full test run:** run the complete installer on a fresh system, in a new user account or a virtual machine, then remove the work-in-progress label.
