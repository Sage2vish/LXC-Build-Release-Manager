# Plan — Main panel: Header (top)

> **Owns:** the top band of the centre column: repository identity, path lines, the three repo-wide actions, and the appearance and language controls.
>
> The top band of the [main panel](Plan-MainPanel-todo.md). Siblings:
> [Toolbar](Plan-MainPanel-Toolbar-todo.md) · [Container](Plan-MainPanel-Container-todo.md)

The identity band for whatever repository is open: what it is, where it lives, and the three
actions that act on the repository as a whole.

## What it contains

| Element | Detail |
| --- | --- |
| Repository name | Large, the primary identifier |
| Connection badge | Connected / No /build folder / No scripts found / Unreachable / scanning |
| Local folder | Labelled path line, middle-truncated |
| GitHub | Labelled origin line, shown only when the repository has one |
| Actions | Reveal in Finder · Open in Terminal · Copy Path |

## Work plan

## Already shipped

- [x] Repository name with the connection badge beside it.
- [x] Labelled `Local folder:` line.
- [x] Labelled `GitHub:` line, hidden when the repository has no origin.
- [x] Reveal in Finder, Open in Terminal, Copy Path, each disabled when not applicable.
- [x] Accessibility labels on all three actions.
- [x] Paths middle-truncate rather than pushing the actions off-screen.

## 01. Glass effect

The header currently sits on the flat window background, so it reads as part of the content
rather than as a band above it.

- [x] Give the header a translucent material background so it reads as a distinct band. Header and toolbar share one chrome band.
- [x] Respect the existing **Reduce transparency** preference — falls back to `windowBackgroundColor`.
- [ ] Keep the text legible over the material in both light and dark.
- [ ] Make sure the material does not fight the accent colour used by the three action buttons.
- [ ] Verify at the minimum panel width, where the actions are closest to the title.

## 02. Open items

- [ ] Extract the header into its own view; it still lives inside `RepositoryDetailView`.
      *(Carried from the refactoring plan, section 04.)*
- [ ] The GitHub line has no edit affordance here — it is only settable from the Settings tab.
      Decide whether that is right or whether the header should offer it.

## 03. Theme and language pickers — top band, right side

Two settings are reached often enough that burying them in Preferences is wrong: **appearance**
and **language**. Both get a compact control in this band, right-aligned, opposite the repository
identity on the left.

The shared rule for both: **no label outside the control.** The segments carry their own words, so
the control explains itself without a "Theme:" prefix eating horizontal space next to a repository
name that already truncates.

**Boundary.** This band owns the *controls* — that they exist, where they sit, how they look, and
that they move the right preference. What the preference then *does* belongs elsewhere:
appearance to [`Plan-PreferenceScreen-todo.md`](Plan-PreferenceScreen-todo.md), language switching
to [`Plan-Localization-todo.md`](Plan-Localization-todo.md). Neither control introduces a new
setting; both drive the value that already exists, so Preferences and the header can never
disagree.

### Appearance picker

- [x] A three-stop **slider** — Bright · Default · Dark — with the knob travelling between stops,
      so the current state reads at a glance instead of by comparing three similar segments.
      System sits in the **middle**: it is the resting position, with an override either side.
- [x] Bound to the existing `theme` preference — not a new one — so changing it here updates
      Preferences → Appearance, and vice versa, with no second source of truth.
- [x] Applies immediately, with no restart and no confirmation.
- [x] No text in the appearance control at all, so nothing can clip in any language; the
      words live in tooltips and accessibility labels, which are localized.
- [x] **Project SVG icons**, not SF Symbols: sun, split circle and crescent live in the asset
      catalogue as vector data with template rendering, so they stay crisp at any size and tint
      with the label colour. Icons rather than words also keep the control narrow at every width.
- [x] Accessibility: the control is one labelled radio group; each segment states what it selects.
- [x] Survives a relaunch, because it writes the same persisted preference.

### Language picker

- [x] A picker listing every language the app actually ships — today English and Hindi — read from
      the available localizations rather than a hardcoded list, so adding a language adds an entry.
- [x] Each entry reads **English name — native name** (`Hindi — हिन्दी`). Both halves earn their
      place: someone reading the interface in English needs to find "Hindi", while someone who
      reads Hindi scans for "हिन्दी" and may not recognise the English word at all. Where the two
      names are identical the dash is dropped rather than printing "English — English".
- [x] Bound to the existing `language` preference and applied live, through `AppLanguageController`.
- [x] Says plainly if any part of the UI needs a relaunch to fully re-render, rather than leaving a
      half-translated window unexplained.
- [x] Same no-outside-label rule — `labelsHidden()` on both. Preferences → General shows the same
      list in the same words, from the same `AppLanguage` source, so the two surfaces cannot
      describe a language differently.

### Placement, and the open question

- [x] Build both as standalone components so their position is a layout decision, not a rewrite. `App/Views/AppearanceAndLanguageControls.swift`.
- [x] Place them in this band, right-aligned, with the repository identity keeping the left.
- [ ] Confirm the band still holds at the minimum panel width with Reveal / Terminal / Copy Path
      present — that row is already the tightest part of the header.
- [ ] **Decide where language finally lives.** The header is the starting position; the status bar
      is the alternative, since it already carries small persistent state chips. Deliberately left
      open — see [`Plan-StatusBar-todo.md`](Plan-StatusBar-todo.md) section 02.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 6 / 6 | Done |
| 01 — Glass effect | 2 / 5 | In progress |
| 02 — Open items | 0 / 2 | Open |
| 03 — Theme and language pickers | 14 / 16 | Built; needs a GUI pass |
| **Total** | **22 / 29** | **In progress** |
