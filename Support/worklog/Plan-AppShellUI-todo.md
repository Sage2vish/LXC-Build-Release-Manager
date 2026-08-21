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

- [x] **Named once: `GlassSurface`.** A translucent base, a soft smear of light over it, and a lit
      hairline on the edge that faces content. Two weights in use — `.ultraThin` for the two chrome
      bands, `.regular` for the right panel, which carries text and has to stay readable.
- [x] The three surfaces the window is read by are made of it: the band across the top, the status
      strip across the bottom, and the right panel.
- [x] It honours **Reduce transparency** in one place — inside `GlassSurface` — instead of each
      caller remembering to.
- [ ] Apply it to the remaining ad-hoc frostings: the sidebar's own background and footer, and the
      centre column's header band, still build their own material and sheen inline.
- [ ] Re-check contrast over the background image, not over a flat colour.

## 06. The window's chrome bands

macOS draws the toolbar's background across the whole window and gives no way to make it stop at a
column. That is what kept the right panel from reaching the top of the window.

- [x] The toolbar's own background is hidden; the app paints the band itself (`WindowTopChrome`) —
      glass over the sidebar and the centre, the panel's glass over the panel.
- [x] The title bar is made transparent once, from AppKit, when the window first appears. Doing it
      on every pass invalidates the layout from inside the layout it caused: the app spins at 100%
      CPU and never draws a window.
- [x] The band's height is the strip macOS reserves for title bar and toolbar, measured from the
      window rather than guessed.
- [x] The toolbar's buttons are untouched — macOS still draws them on top. Only the background
      moved.
- [ ] Decide where the appearance and language controls belong now that the strip they sit at the
      end of stops at the panel: they currently float above the panel's own glass.

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
- [x] **Equal height, by letting AppKit decide.** Two earlier attempts failed for the same
      reason: a toolbar does not render custom backgrounds behind its items, so a hand-drawn
      capsule never appeared — the appearance control showed as three loose icons and the language
      control as blue link text, with matched numbers and mismatched UI. Both are native controls
      now, a segmented picker and a menu picker, sized by the toolbar itself. Verified in the
      running window: three capsules, one height.
- [x] The bar shows the language's native name; the full `English — native` pairing is in the
      menu, where there is room for it, with a tick against the active language.
- [x] A language picker naming each language in English and in its own script (`Hindi — हिन्दी`).
- [x] Both bind to the preferences Preferences already owns, so the two surfaces cannot disagree.
- [x] Hosted on the app shell rather than the repository detail view, so they never disappear when
      no repository is selected.
- [x] Checked in the real title bar: appearance, language, and the refresh/show-hide pair read as
      three separate capsule groups on one line.
- [ ] Check them at the minimum window width, where all four controls compete for the same strip.
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
| 02 — Material and glass language | 3 / 5 | Named and applied to the three chrome surfaces |
| 03 — Theme and accent | 0 / 3 | Open |
| 04 — App icon | 0 / 7 | Open |
| 05 — Top-bar controls | 8 / 10 | Built; needs a GUI pass |
| 06 — The window's chrome bands | 4 / 5 | Built; control placement open |
| **Total** | **15 / 38** | **In progress** |
