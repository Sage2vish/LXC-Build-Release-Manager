# Plan — App shell UI (whole window)

> **Owns:** the whole window's visual identity — background, material and glass language, theme and accent — so the four regions stay coherent instead of each inventing a look.
>
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
| `AppIcons/LXC-BRM-AppIcon2.png` | **The app icon.** 1254px source for the `AppIcon` set, the DMG volume icon, and the README |
| `Build-Console-Screen-*.png` | Main panel concepts |
| `Logs-console-Screen-concept01a.png` | Logs concepts |
| `Preference-Screen/` | The seven Preferences tabs — owned by [Plan-PreferenceScreen-todo.md](Plan-PreferenceScreen-todo.md) |

## Work plan

## 01. Window background

- [x] Ship `ui-back-main.png` as a bundled app resource, registered in the target exactly once. The bundle lookup now resolves it from `Assets/` or the bundle root, and the regression test passes.
- [x] Render it behind the whole window, beneath all four regions.
- [x] Remove opaque detail-view backgrounds that sat on top of the shell art and made the image look missing.
- [x] Give the left sidebar, detail header, inspector, and status bar a shared frosted-glass sheen so they read as smudged glass over the background art.
- [ ] Scale it to fill without distorting — the window's aspect ratio will not match 3:2.
- [ ] Keep it subtle enough that body text stays comfortably readable on top of it.
- [ ] Respect the **Reduce transparency** preference: fall back to a plain surface when it is on.
- [x] Decide what happens in dark mode — the asset stays visible, but with a darker overlay so it
      does not wash out the content.
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

## 05. Appearance and language in the window top bar

Two app-wide settings that belong to the window rather than to any repository: the appearance
slider and the language picker. They sit at `.principal` placement — the middle of the title bar —
so they are reachable from every tab and present even with no repository open.

- [x] A three-stop appearance slider — Bright · Default · Dark — with a travelling knob and
      project SVG icons, tinted as templates so they follow the label colour.
- [x] **Two separate toolbar items, not one clump.** Each is its own `ToolbarItem`, so macOS gives
      them its own spacing and either can move or be hidden without touching the other.
- [x] **Equal height, structurally.** Both are built on one `ToolbarPill`, whose height is
      `LayoutMetrics.toolbarControlHeight`. The previous attempt set a frame on each and they
      still disagreed: a `.menu` picker draws its own control chrome at its own intrinsic height
      and ignored the frame. The language control is a `Menu` in the same pill instead, so the two
      heights cannot drift — and a test reads both from the same constant.
- [x] The bar shows the language's native name; the full `English — native` pairing is in the
      menu, where there is room for it, with a tick against the active language.
- [x] A language picker naming each language in English and in its own script (`Hindi — हिन्दी`).
- [x] Both bind to the preferences Preferences already owns, so the two surfaces cannot disagree.
- [x] Hosted on the app shell rather than the repository detail view, so they never disappear when
      no repository is selected.
- [ ] Check the pair in the real title bar at the minimum window width, where the sidebar toggle,
      Rescan and the inspector toggle are competing for the same strip.
- [ ] Decide whether language stays here or moves to the status bar — the alternative is recorded
      in [`Plan-StatusBar-todo.md`](Plan-StatusBar-todo.md) section 02. Both are one-line moves now.

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
| 05 — Top-bar controls | 8 / 10 | Built; needs a GUI pass |
| **Total** | **8 / 32** | **In progress** |
