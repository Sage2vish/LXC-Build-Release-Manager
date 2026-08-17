# Plan — Status Bar (bottom)

> The fourth region of the window. The other three have their own plans:
> [left sidebar](Plan-LeftSidebar-todo.md) · [main panel](Plan-MainPanel-todo.md) ·
> [right Detail View panel](Plan-DetailViewPanel-todo.md).

A single strip across the bottom of the window showing the state of the current repository at a
glance, without taking a click to find out.

## What it shows

| Chip | Source | Notes |
| --- | --- | --- |
| **Repository** | Selected repository name | `—` when nothing is selected |
| **Branch** | `.git/HEAD`, read from disk | `—` for GitHub-sourced repositories with no local checkout |
| **Platform** | Static: macOS | Placeholder for when other targets exist |
| **Auto-detect** | `autoDetectRepositoriesOnStartup` | Shows Enabled / Disabled, with a muted style when off |

## Already shipped

Consolidated from `Plan-WindowLayout-todo.md`, `todo-2026-08-16.md`, and the worklog.

- [x] Status bar spans the full window width at the bottom.
- [x] Colour-coded chips per field, with a muted disabled state for auto-detect.
- [x] Branch read from `.git/HEAD` for local repositories.
- [x] Reflects the live preferences object rather than a snapshot.
- [x] **Show Status Bar (Bottom)** in the View menu, toggling visibility.
- [x] Visibility persists across relaunch.
- [x] Rendered as a sibling below the split view, not a `safeAreaInset` — an inset does not
      propagate into the sidebar's own safe area, which was clipping the sidebar footer.
- [x] Hiding it reclaims the strip rather than leaving a blank band.
- [x] Localizable through the string catalog.

## 01. Known gaps

- [ ] Branch shows `—` for GitHub-sourced repositories, because there is no local `.git` to read.
      Decide whether to fetch the default branch or keep it blank and say why.
- [ ] Detached HEAD shows a short SHA rather than a branch name. Decide whether that is correct
      or should read "detached".
- [ ] The branch is read once and never refreshed, so switching branches outside the app leaves
      the chip stale until the repository is reselected.
- [ ] Platform is hard-coded to macOS and carries no real information yet.

## 02. Possible additions

Not committed to — listed so the ideas are not lost.

- [ ] Show the active build, if any, so a running build is visible from any tab.
- [ ] Show the count of repositories, or the last build result.
- [ ] Make a chip clickable — Repository jumping to Overview, Branch revealing the repo in Finder.

## Non-Goals

- No second row; it stays one strip.
- No per-repository customisation of which chips appear.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 9 / 9 | Done |
| 01 — Known gaps | 0 / 4 | Open |
| 02 — Possible additions | 0 / 3 | Not committed |
| **Total** | **9 / 16** | **In progress** |
