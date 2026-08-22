# Plan — Main panel: Header (top)

> **Owns:** the top band of the centre column: repository identity, path lines, the repo-wide actions, and the appearance and language controls.
>
> The top band of the [main panel](Plan-MainPanel-todo.md). Siblings:
> [Toolbar](Plan-MainPanel-Toolbar-todo.md) · [Container](Plan-MainPanel-Container-todo.md)

The identity band for whatever repository is open: what it is, where it lives, and the
actions that act on the repository as a whole.

## What it contains

| Element | Detail |
| --- | --- |
| Repository name | Large, the primary identifier |
| Connection badge | Connected / No /build folder / No scripts found / Unreachable / scanning |
| Local folder | Labelled path line, middle-truncated |
| GitHub | Labelled origin line, shown only when the repository has one |
| Actions | Reveal in Finder · Open in Terminal · Copy Path · Scan Repo |

## Work plan

## Already shipped

- [x] Repository name with the connection badge beside it.
- [x] Labelled `Local folder:` line.
- [x] Labelled `GitHub:` line, hidden when the repository has no origin.
- [x] Reveal in Finder, Open in Terminal, Copy Path, each disabled when not applicable.
- [x] Scan Repo button beside Copy Path opens the repository self-identification scan sheet and
      forces a fresh scan.
- [x] Accessibility labels on all four actions.
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

## 03. Appearance and language — moved to the window top bar

Built here first, then moved. These are **app-wide** settings, and this band is **repository
identity**: putting them together made the header answer two different questions. They now live in
the window's own top bar, at `.principal` placement, which also means they stay present when no
repository is selected — something a control inside the repository header could never do.

- [x] Both controls built as standalone components, which is exactly why the move cost one line
      rather than a rewrite.
- [x] Moved to the window top bar. → [`Plan-AppShellUI-todo.md`](Plan-AppShellUI-todo.md) section 05
      now owns them; this band is repository identity again.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 7 / 7 | Done |
| 01 — Glass effect | 2 / 5 | In progress |
| 02 — Open items | 0 / 2 | Open |
| 03 — Appearance and language | 2 / 2 | Moved to the app shell |
| **Total** | **11 / 16** | **In progress** |
