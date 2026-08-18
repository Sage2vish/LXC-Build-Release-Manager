# Plan — Detail View Panel (right sidebar)

> **Owns:** the right inspector column: its cards, its width, and its visibility.
>
> Named the **Detail View Panel** to match what the View menu already calls it — *Show Detail
> View Window (Right Side)* — and to stay distinct from the left sidebar, which has its own plan
> in [`Plan-LeftSidebar-todo.md`](Plan-LeftSidebar-todo.md).

The right-hand inspector column of the main window. It carries the detail for whatever is
selected in the centre: the script's full path, its build parameters and resolved command, the
current build status, recent history, and the quick actions.

## What it contains

| # | Card | What it is |
| --- | --- | --- |
| 1 | **Selected Script** | Name, location badge, full path wrapped rather than truncated, Copy Path |
| 2 | **Build Parameters** | Parameter controls, the resolved command, and a Run Build button |
| 3 | **Build Status** | Live progress with Stop while running; the last result when idle |
| 4 | **Build History** | The five most recent runs, with View All jumping to the History tab |
| 5 | **Quick Actions** | Open Logs Folder, Export Current Log |

## Work plan

## Already shipped

- [x] Toggleable from the View menu as *Show Detail View Window (Right Side)*, persisting across relaunch.
- [x] Toolbar button toggles the same shared preference, so the two can never disagree.
- [x] Build Parameters and the resolved command moved here out of the centre column.
- [x] Selected script's full path shown wrapped, with Copy Path.
- [x] Resolved command wraps instead of truncating.
- [x] Column widened from a 340pt cap to min 320 / ideal 460 / max 900.
- [x] Behaves when no repository is selected.
- [x] Inspector keeps a glass-like material surface even when the app shell background image changes, so the right panel still reads as frosted rather than flat.

## 00. One column, one card language

The five cards had drifted into three shapes — a caption title inside, a headline title inside, a
`GroupBox` label outside, and one card with no title at all. Three treatments in one column read
as three unrelated widgets rather than one panel.

- [x] One `InspectorCard`: a tinted **ribbon** carrying the title, over the content. Every card
      separates the same way, and a card is separable at a glance.
- [x] Selected Script and Build Parameters moved their titles into the ribbon; Build Parameters'
      spinner and Build History's "View All" became ribbon accessories rather than title-row
      improvisations.
- [x] **Each section is a rounded box.** Tried square-with-a-tab first, at your direction, and
      seeing it settled the question: the sections read better as rounded boxes. The label keeps
      its square bottom edge — it is a header band across the top of the box, not a floating tab —
      but its top corners follow the box's radius so the tint reaches the corner instead of
      leaving two square shoulders inside a rounded card.
- [x] Cards are separated by a gap and sit inside a margin. Rounded boxes butted together read as
      one shape with lines drawn across it; the radius and the gap are both named defaults.
- [x] The detail line — a script filename, a run count — sits **inside the box**, not in the
      label. The label names the section and nothing else; a filename in it made the label two
      things at once.
- [x] **Matte, not glass.** The translucent material pulled the desktop through the one column
      whose job is to be read, and its softLight sheen made the top brighter than the bottom. The
      cards are a bright flat surface on a slightly darker panel, so the seams stay visible.
- [x] Cards run edge to edge and butt against each other — no gaps, no outer padding.
- [ ] Check the ribbon tint against a custom accent colour: it is derived from the accent, and a
      saturated accent could make five stacked ribbons loud.

## 01. The window will not resize while the panel is open — BUG

Reported: with the Detail View panel open, the **whole application window** cannot be resized.
The panel's own divider still drags, and the panel itself behaves; it is the window frame that
will not move.

The likely cause is a minimum-width pile-up. The window's minimum is the sum of every column's
minimum, and those minimums were each raised independently for good local reasons:

| Column | Minimum | Set for |
| --- | --- | --- |
| Left sidebar | 180 | Keeping the footer buttons legible |
| Centre — Docs explorer | 220 | Showing a readable file tree |
| Centre — Docs document | 380 | Rendering a document without reflow thrash |
| Detail View panel | 320 | Fitting parameter controls and a wrapped command |

Together those exceed what the user can shrink to, so the window appears frozen at the left edge
even though nothing is explicitly locked.

- [x] Reproduce it: measured **1853pt with the panel open, 1393pt closed**.
- [x] Confirm whether the freeze is total or only below a threshold. **Not a freeze — a floor.** The window resizes normally above its minimum; the minimum was simply larger than the user's target.
- [x] Check whether the Docs tab's `HSplitView` minimums contribute. They do — explorer 220 + document 380.
- [x] Lower the minimums to values that still work. Docs explorer 220→170, document 380→260, and the scripts table's four hard `.frame(width:)` columns became `minWidth/idealWidth/maxWidth` so they compress instead of acting as a floor.
- [x] Make the Detail View panel's minimum smaller: `min: 320, ideal: 460` → `min: 240, ideal: 340`.
- [ ] Verify the window resizes freely with the panel open, on the Build tab and the Docs tab.
- [ ] Verify it still resizes with the panel closed, and with the left sidebar hidden.
- [ ] Verify the columns still look right at the new minimum rather than merely fitting.
- [ ] Add a regression note recording the measured minimum, so a future width change is a
      deliberate decision instead of an accident.

## 02. Follow-ups

- [ ] Split the inspector into its own view; it still lives inside `RepositoryDetailView`.
      *(Carried from the refactoring plan, section 04.)*
- [ ] Move the refresh and right-panel toggle controls into the repository header in the main
      workspace chrome, then leave the inspector as a plain glass slab with only the card stack
      inside it.
- [ ] The panel shows build-oriented cards on every tab, including Docs, where they are not
      relevant. Decide whether it should be tab-aware.

## Non-Goals

- No detaching the panel into a separate window.
- No change to what the cards show; this plan is about the panel, not its contents.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 7 / 7 | Done |
| 00 — One column, one card language | 7 / 8 | Needs an accent check |
| 01 — Window resize bug | 5 / 9 | Improved 1853 → 1513; verification open |
| 02 — Follow-ups | 0 / 2 | Open |
| **Total** | **19 / 26** | **In progress** |

## Measured result

| State | Minimum window width before | After |
| --- | --- | --- |
| Detail View panel open | 1853pt | **1513pt** |
| Panel closed | 1393pt | 1393pt |
| Both side panels hidden | 817pt | 817pt |

The remaining floor is the centre column itself — the tab picker, the header's three action
buttons, and the scripts table together will not compress below roughly 817pt. Going lower means
changing what the centre shows at narrow widths, which is a design decision rather than a
constraint tweak, so it is left open rather than forced.
