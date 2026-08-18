# Plan — Status Bar (bottom)

> **Owns:** the strip across the bottom of the window and every chip in it.
>
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

## Work plan

## Already shipped

Consolidated from [`Plan-WindowLayout-todo.md`](Plan-WindowLayout-todo.md) and the retired dated
checklist and worklog.

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

- [x] **Decided: keep it blank, and say why.** A GitHub-sourced repository has no checkout, so
      there is no `.git/HEAD`; fetching a default branch over the network would put a number in
      the chip that does not describe anything on this machine. The chip now carries a tooltip
      explaining the gap and what to do about it — add the repository as a local folder.
- [x] **Detached HEAD reads `detached @ 1a2b3c4`** — the word first, so it is legible as a state
      rather than as a strangely-named branch, and the short SHA after it, because that is the only
      thing identifying where you are. The tooltip says what detached means.
- [x] Re-reads `.git/HEAD` when the window becomes active again, and on click. Branches change
      in a terminal while the app sits open, so the chip has to catch up at the moment attention
      returns to the window — without polling the file on a timer.
- [ ] Platform is hard-coded to macOS and carries no real information yet.

## 02. Possible additions

Not committed to — listed so the ideas are not lost.

- [ ] Show the active build, if any, so a running build is visible from any tab.
- [ ] Show the count of repositories, or the last build result.
- [ ] Make a chip clickable — Repository jumping to Overview, Branch revealing the repo in Finder.
- [ ] **Host the language picker here instead of the header.** This strip already carries small,
      persistent state, and language is closer to that than to repository identity. The control is
      being built in the header first; if it belongs here, only its placement moves. See
      [`Plan-MainPanel-Header-todo.md`](Plan-MainPanel-Header-todo.md) section 03.

## Non-Goals

- No second row; it stays one strip.
- No per-repository customisation of which chips appear.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 9 / 9 | Done |
| 01 — Known gaps | 3 / 4 | Platform chip still cosmetic |
| 02 — Possible additions | 0 / 4 | Not committed |
| **Total** | **12 / 17** | **In progress** |
