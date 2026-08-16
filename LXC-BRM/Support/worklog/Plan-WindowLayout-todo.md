# Plan — Window Layout & View Menu (v0.1.2)

Scope: the app **shell** only — the left repository container, the sidebar footer controls, the bottom status bar, the right detail/inspector panel, and the View menu entries that show/hide them. No Build tab, Logs, History, Overview, or Preferences *content* work in this pass.

Source: verbal request, 2026-08-16. Read against `context/rules-context.md` and the existing shell code in `App/ContentView.swift`.

`[x]` = built and verified (compiles + traced). `[ ]` = not done. A box is only checked when the matching code exists and the target builds.

---

## Current State (verified in code before planning)

| Thing | Where it lives now | Problem |
| --- | --- | --- |
| Sidebar width | `ContentView.swift:111` — `.navigationSplitViewColumnWidth(preferencesStore.preferences.sidebarWidthPoints)` | Single-value form **pins** the column. macOS removes the drag handle, so the user cannot resize it with the mouse. |
| Sidebar footer | `ContentView.swift:112-140` — `.safeAreaInset(edge: .bottom)` on the sidebar `List` | Buttons exist ("Open Repository…" + gear "Preferences"), but the window-wide status bar is a `safeAreaInset` on the whole `NavigationSplitView`, so the two insets fight for the same bottom strip. |
| Status bar | `ContentView.swift:46-48` → `Views/StatusBar.swift` | Always visible. No way to hide it. |
| Detail/inspector panel | `ContentView.swift:531` — `@State private var showInspector` inside `RepositoryDetailView` | State is **private to the detail view**. A menu command at `Scene` level cannot reach it. Only reachable via the toolbar button at `ContentView.swift:616-622`. |
| View menu | — | No `.commands` block exists anywhere in the app. `LXC_BRMApp.swift` has only `WindowGroup` + `Settings`. |
| Version | `project.pbxproj:528, 615` — `MARKETING_VERSION = 1.0` | Should be `0.1.2`. |

---

## Phases

### Phase 1 — Shared Layout State ✅

The three View-menu toggles must be readable and writable from **both** the `Scene`/`Commands` level and from inside `ContentView`/`RepositoryDetailView`. Today `showInspector` is private `@State`, which makes that impossible.

- [x] Add three layout flags to the `Preferences` model (`Models/Preferences.swift`, `05 Appearance` block), so they persist to `preferences.json` like every other setting:
  - [x] `showStatusBar = true`
  - [x] `showRepositorySidebar = true`
  - [x] `showDetailInspector = true`
- [x] Confirm `Preferences` stays `Codable`/`Equatable` and that older `preferences.json` files without these keys still decode (defaulted properties, no custom `init(from:)` needed).
- [x] Route all three through `PreferencesStore.shared` so the menu, the main window, and the Preferences window all observe one source of truth.
- [ ] Verify a menu toggle writes through to disk and survives an app restart.

### Phase 2 — Left Container Is Mouse-Resizable

- [x] Replace the fixed `.navigationSplitViewColumnWidth(_:)` at `ContentView.swift:111` with the `min:ideal:max:` form so macOS restores the drag handle.
- [x] Use the saved `sidebarWidthPoints` as the `ideal` value so the Appearance preference still seeds the starting width.
- [x] Pick sane bounds (min ~180, max ~420) so the sidebar cannot be dragged to unusable extremes.
- [x] Confirm the divider between the sidebar and the detail view actually drags with the mouse.
- [x] Confirm the sidebar rows, section headers, and footer buttons all reflow correctly at both the minimum and maximum width.
- [x] Confirm changing "Sidebar Width" in Preferences still takes effect and does not fight the user's manual drag.

### Phase 3 — Sidebar Footer Above The Status Bar

- [x] Confirm "Open Repository…" sits directly above the gear "Preferences" button, stacked vertically, pinned to the bottom of the left container.
- [x] Ensure the footer renders **above** the bottom status bar and is never clipped or overlapped by it.
- [x] Verify the gear "Preferences" button opens the native Settings window via `openSettings()`.
- [x] Verify the footer stays pinned and fully visible when the repository list is long enough to scroll.
- [x] Verify the footer stays fully visible when the status bar is hidden via the View menu.
- [x] Verify the footer survives the sidebar being resized to its minimum width without the labels truncating badly.

### Phase 4 — View Menu Commands

- [x] Add a `.commands { }` block to `LXC_BRMApp.swift` (none exists today).
- [x] Place the entries in the **View** menu using `CommandGroup(after: .sidebar)` — that group renders under View on macOS.
- [x] Add **Show Status Bar (Bottom)** as a checked/toggling menu item.
- [x] Add **Show Repo Window (Left side)** as a checked/toggling menu item.
- [x] Add **Show Detail View Window (Right Side)** as a checked/toggling menu item.
- [x] Show a checkmark next to each item reflecting current visibility (use `Toggle`, which macOS renders as a checked menu item).
- [x] Keep the menu wording exactly as requested above.

### Phase 5 — Wire The Toggles To Real Behavior

- [x] **Status bar:** apply the bottom `safeAreaInset` conditionally on `showStatusBar` so hiding it reclaims the strip instead of leaving a blank gap.
- [x] **Repo window:** drive `NavigationSplitView`'s `columnVisibility` binding from `showRepositorySidebar` (`.all` when shown, `.detailOnly` when hidden).
- [x] Keep `columnVisibility` and the preference in sync in **both** directions, so collapsing the sidebar with the native toolbar control also unchecks the menu item.
- [x] **Detail view window:** lift `showInspector` out of `RepositoryDetailView`'s private `@State` and bind `.inspector(isPresented:)` to the shared preference.
- [x] Keep the existing "Toggle Build Panel" toolbar button (`ContentView.swift:616-622`) working against the same shared flag so the toolbar and the menu never disagree.
- [x] Confirm the inspector toggle still behaves when no repository is selected (the detail view is a `ContentUnavailableView` in that case).
- [x] Confirm hiding all three at once still leaves a usable window.

### Phase 6 — Version Bump To 0.1.2

- [x] Set `MARKETING_VERSION = 0.1.2` in both build configurations (`project.pbxproj:528` and `:615`).
- [x] Bump `CURRENT_PROJECT_VERSION` in both configurations.
- [x] Confirm the version reads correctly in the built app (`CFBundleShortVersionString` = `0.1.2`, `CFBundleVersion` = `2`).

### Phase 7 — Verification

- [x] `xcodebuild build` returns `BUILD SUCCEEDED` with no new warnings.
- [x] Drag the sidebar divider and confirm it resizes.
- [x] Toggle each of the three View menu items off and back on; confirm the checkmarks track the real state.
- [ ] Quit and relaunch; confirm all three visibility states persisted. **Status bar and detail panel persist; the sidebar does not — see the caveat below.**
- [x] Confirm the sidebar footer buttons are fully visible and clickable in every combination of the three toggles.
- [x] Update `worklog-2026-08-16.md` with what actually shipped, then flip the tracking table below.

---

## Files Expected To Change

| File | Change |
| --- | --- |
| `App/Models/Preferences.swift` | Three new layout flags in the Appearance block. |
| `App/LXC_BRMApp.swift` | New `.commands` block with the three View menu items. |
| `App/ContentView.swift` | Resizable column width, conditional status bar inset, `columnVisibility` binding, inspector flag lifted to the shared store. |
| `LXC-BRM.xcodeproj/project.pbxproj` | `MARKETING_VERSION` → `0.1.2`. |

---

## Explicitly Out Of Scope

1. Any change to the Build, Logs, History, Overview, or Settings **tab content**.
2. Any redesign of the status bar chips themselves — only its visibility changes.
3. Any new Preferences **UI** rows for the three new flags (the menu is the control surface for v0.1.2).
4. The open items still tracked in `BuildScreen-plan-todo.md` and `todo-2026-08-16.md`.

---

## Tracking

| Phase | Checked / Total | Status |
| --- | --- | --- |
| 1 — Shared Layout State | 5 / 6 | Done (1 caveat) |
| 2 — Left Container Resizable | 6 / 6 | Done |
| 3 — Sidebar Footer Placement | 6 / 6 | Done |
| 4 — View Menu Commands | 7 / 7 | Done |
| 5 — Toggles Wired To Behavior | 7 / 7 | Done |
| 6 — Version Bump 0.1.2 | 3 / 3 | Done |
| 7 — Verification | 5 / 6 | Done (1 caveat) |
| **Total** | **39 / 41** | **Shipped — see caveat below** |

## Caveat Found During Verification

**Sidebar visibility does not survive a relaunch.** The status bar and the right detail panel
both persist correctly across quit/relaunch (verified by seeding `preferences.json` and
restarting). The left repo sidebar does not: macOS's own window-state restoration re-expands
the split view's sidebar column on launch and writes that back through the
`NavigationSplitView` visibility binding, overwriting the saved `false`.

A 400ms guard on the binding setter was tried and did not hold — the restoration write lands
after it — so the guard was removed rather than left in as an ineffective hack. Hiding and
showing the sidebar works correctly for the whole session; it just reopens visible.

Worth revisiting with an `NSSplitViewItem.isCollapsed` bridge if the persistence matters.

## Verification Evidence

- `xcodebuild ... build` → `BUILD SUCCEEDED`, no new warnings.
- All three items confirmed present in the live View menu via accessibility query.
- Each item clicked through the real menu; `preferences.json` observed changing on disk.
- Screenshots captured of all-panels-visible and all-panels-hidden states.
- Sidebar toggle round-tripped off→on→off cleanly after the binding was made single-source.
- The original bug is fixed and visually confirmed: the "Preferences" button in the sidebar
  footer was being clipped by the status bar, and now renders fully above it.
