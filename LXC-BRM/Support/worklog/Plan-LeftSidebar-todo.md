# Plan — Left Sidebar Panel

> Named **left** sidebar deliberately: the app has a right sidebar too — the Detail View Window
> inspector — and "sidebar" alone is ambiguous once both exist.

The single home for everything in the left panel, including how repositories enter the app at all.
Sidebar work was previously scattered across the dated master checklist,
`Plan-WindowLayout-todo.md`, `Plan-PreferenceScreen-todo.md`,
`Plan-CodeRefactoring-Reusability-todo.md`, and the dated worklog; it is consolidated here, with
what is already shipped recorded so nothing gets rebuilt by accident.

## The four features of the panel

| # | Feature | What it is |
| --- | --- | --- |
| 1 | **Repositories** | Every added repository. Pinned first, then most recently accessed. Section header carries the inline **+**. |
| 2 | **Recent Repositories** | The most recently opened repositories as one-click shortcuts, capped by the Preferences value. |
| 3 | **Open Repository…** | Footer button; local-folder shortcut straight to the picker. |
| 4 | **Preferences** | Footer gear; opens the native Settings window. Also reachable with Cmd+, **The button belongs to this panel; everything inside that window is owned by [`Plan-PreferenceScreen-todo.md`](Plan-PreferenceScreen-todo.md) and is not duplicated here.** |

Everything else in the panel — width, show/hide, footer placement — serves those four.

## Already shipped

Recorded here so it is not re-planned. Each was verified when it landed.

- [x] "Repositories" section header with an inline **+** button.
- [x] "Recent Repositories" section, capped by `maxRecentRepositories`.
- [x] Footer with **Open Repository…** above the **Preferences** gear, pinned below the list.
- [x] Footer sits above the status bar and is never clipped by it.
- [x] Relative "last accessed" time on each repository row.
- [x] Visible remove control (✕) on the row, not only in a context menu.
- [x] Pin / favourite, with pinned repositories sorted to the top.
- [x] Context menu per row: Reveal in Finder, Open in Terminal, Copy Path.
- [x] Sidebar width follows the Appearance preference, and stays mouse-resizable (min 180 / max 420).
- [x] Show / hide from the View menu, persisting across relaunch.
- [x] Empty state when no repositories have been added.

## 01. Name and path visibility

The row currently always prints the full path under the name. On a deep checkout that is the
longest thing in the panel, it truncates to uselessness, and it is the same prefix on every row.

The **name is identity and is always shown**. The **path is detail and should be optional**.

- [x] Add a persisted preference for whether the path shows under the repository name.
- [x] Default it to showing the path, so nothing changes for anyone until they ask.
- [x] Put the control in the "Repositories" section header as a symbol button, next to **+**.
- [x] Use a symbol that reads as show/hide detail, and flip it to reflect the current state.
- [x] The name must never be hideable — a row with no name is not identifiable.
- [x] Apply to both the Repositories rows and the Recent Repositories rows.
- [x] Keep the "last accessed" line independent of this toggle.
- [x] Rows must reflow cleanly at both the minimum and maximum sidebar width in both states.
- [x] Accessibility: the row keeps its full description including the path, even when the path
      is visually hidden, so VoiceOver users are not deprived of it.
- [x] Tooltip on the toggle stating exactly what it does.
- [x] Mirror the setting in Preferences → Appearance so it is discoverable from there too.
- [x] Tests: the preference round-trips, defaults correctly, and an unknown stored value is safe.

## 02. Consolidation carried over

Open items about this panel that were living in other plans.

- [ ] Extract the sidebar composition out of `ContentView`, keeping `RepositoryRow` and
      `RecentRepositoryRow` reusable with injected stores rather than reaching for singletons.
      *(Carried from the refactoring plan, section 04.)*

## 03. Repository input and multi-repository support

Requirements §1 and §5. This is how a repository gets into the app and how several coexist —
it belongs to this panel because the sidebar is the surface that owns it. What happens *inside*
a repository once selected — scanning `/build/scripts`, running a script — belongs to
[`Plan-Tab-Build-todo.md`](Plan-Tab-Build-todo.md).

- [x] Validate the source before accepting it: a GitHub URL is checked for a `github.com` host
      and an owner/repo path before the Add button enables; a local path is always valid because
      it comes from a folder picker.
- [x] Add a repository through a local folder picker (`NSOpenPanel`) or a pasted GitHub URL.
- [x] Persist the repository list as JSON in Application Support, so it survives a restart.
- [x] Add and remove repositories.
- [x] List every opened and recent repository; switching between them is instant, with no
      loading screen.
- [x] Switching refreshes the build buttons, clears the log display, and reloads that
      repository's stats and history — the detail view is keyed to the repository id, so all
      `@State` resets on switch.
- [x] Build history stays isolated per repository, keyed by repository UUID.
- [x] Each repository keeps its own discovered scripts within a session.

## Boundary with the Preferences plan

This panel owns the **gear button**: that it exists, sits in the footer above the status bar,
is reachable at Cmd+, and opens the Settings window. That is the whole of its responsibility here.

Every setting inside that window — the seven tabs, their controls, their wiring, and their
save/cancel behaviour — belongs to [`Plan-PreferenceScreen-todo.md`](Plan-PreferenceScreen-todo.md).
Anything about *what a preference does* goes there, not here.

- [x] The footer gear opens the native Settings scene.
- [x] Cmd+, opens the same window.
- [ ] Everything else about Preferences → see `Plan-PreferenceScreen-todo.md`.

## Non-Goals

- No drag-to-reorder of repositories; ordering is pinned-then-recent by design.
- No nested grouping or folders of repositories.
- No change to how repositories are added, removed, or scanned.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 11 / 11 | Done |
| Preferences boundary | 2 / 3 | Pointer to the Preferences plan |
| 01 — Name and path visibility | 12 / 12 | Done |
| 02 — Consolidation carried over | 0 / 1 | Open |
| 03 — Repository input and multi-repository | 8 / 8 | Done |
| **Total** | **33 / 35** | **In progress** |
