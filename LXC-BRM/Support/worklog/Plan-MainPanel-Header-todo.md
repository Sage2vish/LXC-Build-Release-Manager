# Plan — Main panel: Header (top)

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

- [ ] Give the header a translucent material background so it reads as a distinct band.
- [ ] Respect the existing **Reduce transparency** preference — fall back to a solid surface
      when it is on, rather than ignoring the setting.
- [ ] Keep the text legible over the material in both light and dark.
- [ ] Make sure the material does not fight the accent colour used by the three action buttons.
- [ ] Verify at the minimum panel width, where the actions are closest to the title.

## 02. Open items

- [ ] Extract the header into its own view; it still lives inside `RepositoryDetailView`.
      *(Carried from the refactoring plan, section 04.)*
- [ ] The GitHub line has no edit affordance here — it is only settable from the Settings tab.
      Decide whether that is right or whether the header should offer it.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 6 / 6 | Done |
| 01 — Glass effect | 0 / 5 | Open |
| 02 — Open items | 0 / 2 | Open |
| **Total** | **6 / 13** | **In progress** |
