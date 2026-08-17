# Plan — App shell UI (whole window)

> The visual identity of the **whole LXC Build Release Manager window**, above and across the four regions. Anything
> scoped to one region belongs to that region's plan instead:
> [left sidebar](Plan-LeftSidebar-todo.md) · [main panel](Plan-MainPanel-todo.md) ·
> [Detail View panel](Plan-DetailViewPanel-todo.md) · [status bar](Plan-StatusBar-todo.md).

This plan owns the things that must be decided **once for the app** — the background, the
material and glass language, the accent and theme handling — so the four regions stay coherent
instead of each inventing its own look.

## Design source

Concepts live in `Support/context/concepts-designs/`:

| Asset | Use |
| --- | --- |
| `ui-back-main.png` | The window background. 1536×1024 soft pastel gradient. **Copied to `App/Resources/Assets/` so it ships with the app** — the concepts folder is reference material, not a build input. |
| `brand-mark.svg` | Brand mark |
| `Build-Console-Screen-*.png` | Main panel concepts |
| `Logs-console-Screen-concept01a.png` | Logs concepts |
| `Preference-Screen/` | The seven Preferences tabs — owned by [Plan-PreferenceScreen-todo.md](Plan-PreferenceScreen-todo.md) |

## 01. Window background

- [ ] Ship `ui-back-main.png` as a bundled app resource, registered in the target exactly once.
- [ ] Render it behind the whole window, beneath all four regions.
- [ ] Scale it to fill without distorting — the window's aspect ratio will not match 3:2.
- [ ] Keep it subtle enough that body text stays comfortably readable on top of it.
- [ ] Respect the **Reduce transparency** preference: fall back to a plain surface when it is on.
- [ ] Decide what happens in dark mode — the asset is a light pastel, so it either needs a dark
      counterpart or must be suppressed rather than dimmed into mud.
- [ ] Make sure it does not fight the accent colour or the section cards drawn over it.
- [ ] Confirm it costs nothing meaningful at launch; 1.5 MB decoded once is fine, decoded per
      frame is not.

## 02. Material and glass language

Glass is currently requested per region. Deciding it once here stops three different frostings.

- [ ] Define one material scale — chrome, raised surface, recessed surface — and name it.
- [ ] Apply it through the shared `SectionCard` and the header/toolbar bands rather than ad hoc.
- [ ] Make every material honour **Reduce transparency** in one place.
- [ ] Re-check contrast over the background image, not over a flat colour.

## 03. Theme and accent

- [ ] Verify the whole shell in light and dark, not just light.
- [ ] Confirm the accent preference reaches every region consistently.
- [ ] Check the shell at the minimum window width of 1513pt and at full screen.

## 04. App icon

The app currently ships with no icon, so macOS falls back to the blank generic document icon in
the Dock, the Cmd+Tab switcher, Finder, and the DMG. It is the first thing anyone sees and the
only part of the visual identity that appears before the window does.

- [ ] Design the icon from the existing brand mark
      (`Support/context/concepts-designs/brand-mark.svg`), rather than inventing a second identity.
- [ ] Produce a full `AppIcon` set: 16, 32, 128, 256 and 512 pt, each at 1x and 2x, as macOS
      expects — a single large PNG scaled down reads as mush at 16pt.
- [ ] Follow the macOS icon language: rounded-square silhouette, consistent margins, and a shape
      that survives being 16 points wide.
- [ ] Add an `Assets.xcassets` catalogue with the `AppIcon` set and register it in the target
      exactly once. *(Registration mechanics belong to
      [`Plan-XcodeProject-todo.md`](Plan-XcodeProject-todo.md).)*
- [ ] Check it in the Dock, Cmd+Tab, Finder, Get Info, and on the mounted DMG volume.
- [ ] Check it against both light and dark Dock backgrounds.
- [ ] Decide whether the DMG gets a matching volume icon and background, or stays plain.

## Non-Goals

- No per-repository theming.
- No user-supplied background images.
- No animation on the background.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| 01 — Window background | 0 / 8 | Open |
| 02 — Material and glass language | 0 / 4 | Open |
| 03 — Theme and accent | 0 / 3 | Open |
| 04 — App icon | 0 / 7 | Open |
| **Total** | **0 / 22** | **Open** |
