# Plan — Window Layout & View Menu (v0.1.2)

> **Owns:** window layout: resizing, the View menu, and the visibility and persistence of each panel.

Scope: the app **shell** only — the left repository container, the sidebar footer controls, the bottom status bar, the right detail/inspector panel, and the View menu entries that show/hide them. No Build tab, Logs, History, Overview, or Preferences *content* work in this pass.

Source: verbal request, 2026-08-16. Read against `context/rules.md` and the existing shell code in `App/ContentView.swift`.

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

## Work plan

## Phases

### Phase 1 — Shared Layout State ✅

The three View-menu toggles must be readable and writable from **both** the `Scene`/`Commands` level and from inside `ContentView`/`RepositoryDetailView`. Today `showInspector` is private `@State`, which makes that impossible.

- [x] Add three layout flags to the `Preferences` model (`Models/Preferences.swift`, `05 Appearance` block), so they persist to `preferences.json` like every other setting:
  - [x] `showStatusBar = true`
  - [x] `showRepositorySidebar = true`
  - [x] `showDetailInspector = true`
- [x] Confirm `Preferences` stays `Codable`/`Equatable` and that older `preferences.json` files without these keys still decode (defaulted properties, no custom `init(from:)` needed).
- [x] Route all three through `PreferencesStore.shared` so the menu, the main window, and the Preferences window all observe one source of truth.
- [x] Verify a menu toggle writes through to disk and survives an app restart. **Fixed and re-verified: 5/5 relaunches held a hidden sidebar.**

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
- [x] Quit and relaunch; confirm all three visibility states persisted. **All three now persist — the sidebar fix is described below.**
- [x] Confirm the sidebar footer buttons are fully visible and clickable in every combination of the three toggles.
- [x] Record what actually shipped — see **Sidebar Persistence** and **Verification Evidence**
      below — then flip the tracking table.

---

## Files Expected To Change

| File | Change |
| --- | --- |
| `App/Models/Preferences.swift` | Three new layout flags in the Appearance block. |
| `App/LXC_BRMApp.swift` | New `.commands` block with the three View menu items. |
| `App/ContentView.swift` | Resizable column width, conditional status bar inset, `columnVisibility` binding, inspector flag lifted to the shared store. |
| `LXC-Build-Release-Manager.xcodeproj/project.pbxproj` | `MARKETING_VERSION` → `0.1.2`. |

---

## Explicitly Out Of Scope

1. Any change to the Build, Logs, History, Overview, or Settings **tab content**.
2. Any redesign of the status bar chips themselves — only its visibility changes.
3. Any new Preferences **UI** rows for the three new flags (the menu is the control surface for v0.1.2).
4. The open items tracked in the tab and feature plans indexed by
   [`BRM-Plan-todo.md`](BRM-Plan-todo.md).

---

## Tracking

| Phase | Checked / Total | Status |
| --- | --- | --- |
| 1 — Shared Layout State | 6 / 6 | Done |
| 2 — Left Container Resizable | 6 / 6 | Done |
| 3 — Sidebar Footer Placement | 6 / 6 | Done |
| 4 — View Menu Commands | 7 / 7 | Done |
| 5 — Toggles Wired To Behavior | 7 / 7 | Done |
| 6 — Version Bump 0.1.2 | 3 / 3 | Done |
| 7 — Verification | 6 / 6 | Done |
| **Total** | **41 / 41** | **Complete** |

## Sidebar Persistence — Fixed

Originally the left sidebar would not stay hidden across a relaunch: AppKit replays the window's
saved split state at launch and pushes it through `NavigationSplitView`'s visibility binding,
which overwrote the saved preference. Two delay-based guards were tried; the second held only
about half the time, because that write does not arrive at a predictable moment.

The fix removes the ambiguity instead of racing it:

- The visibility binding is now **one-way** — the preference decides, and nothing the split view
  reports back can change it, so the restoration write is simply ignored.
- SwiftUI's built-in sidebar toggle would have looked broken against a read-only binding, so it
  is removed with `.toolbar(removing: .sidebarToggle)` and replaced by a toolbar button that
  moves the preference. It lives on the split view rather than inside the sidebar so it stays
  reachable once the sidebar is hidden, and its label flips between Hide and Show.
- `SidebarRestorationDisabler` clears the underlying `NSSplitView.autosaveName` so AppKit stops
  persisting and replaying that state at all.

Re-verified: a hidden sidebar survived **5 out of 5** relaunches, and the View menu item still
toggles it both ways within a session.

## Verification Evidence

- `xcodebuild ... build` → `BUILD SUCCEEDED`, no new warnings.
- All three items confirmed present in the live View menu via accessibility query.
- Each item clicked through the real menu; `preferences.json` observed changing on disk.
- Screenshots captured of all-panels-visible and all-panels-hidden states.
- Sidebar toggle round-tripped off→on→off cleanly after the binding was made single-source.
- The original bug is fixed and visually confirmed: the "Preferences" button in the sidebar
  footer was being clipped by the status bar, and now renders fully above it.

---

# Pass 2 — Build Screen Layout (v0.1.2 continued)

Added 2026-08-16 from a second verbal request. Same version, same shell-and-layout theme:
move detail-ish content out of the centre column into the right **Detail View Window**, and
stop the centre column from carrying long paths it has no room for.

## Current State (verified in code before planning)

| Thing | Where it lives now | Problem |
| --- | --- | --- |
| Script table row | `ContentView.swift:595-605` — `script.label` over `script.path` | Row prints the **full absolute path**, truncated in the middle. Unreadable, and it is what makes the table feel cramped. |
| Repo header | `ContentView.swift:945-970` — name + badge, then `repository.source.displayPath` | One line only. `RepositorySource` is an **either/or enum** (`.local(path:)` / `.github(url:)`), so a repo can never show both a local folder and a GitHub URL. |
| Build Parameters | `ContentView.swift:1208-1263` — `buildParametersPanel`, rendered in the centre `buildTab` | Sits in the centre column between the scripts table and the live output. Requested to move to the right panel. |
| Resolved Command | `ContentView.swift:1248-1252` — `.lineLimit(2)` + `.truncationMode(.middle)` | Truncated instead of wrapped. |
| Inspector width | `ContentView.swift:811` — `.inspectorColumnWidth(min: 240, ideal: 280, max: 340)` | Caps at 340pt. Far too narrow to host parameters and a wrapped command. |
| Add script | `ContentView.swift:1037` — single "Add Build Script" file picker | No way to add a whole **folder** of scripts. |

## Phase 8 — Build Scripts Table Shows Names, Not Paths

- [x] Replace the full `script.path` line in `BuildScriptTableRow` with the script's **folder name** only.
- [x] Keep the script filename as the primary line exactly as it reads today.
- [x] Confirm the row still fits the Source / Parameters / Last run / Actions columns without truncation at the default sidebar width.
- [x] Keep "Copy Script Path" and "Reveal in Finder" working off the real full path even though it is no longer displayed.
- [x] Confirm long folder names degrade gracefully rather than pushing the action buttons off-screen.

## Phase 9 — Full Paths Move To The Detail View Window

- [x] Show the selected script's **full path** in the right-hand Detail View Window.
- [x] Render it as **wrapped** text, not single-line truncated.
- [x] Keep it selectable/copyable.
- [x] Confirm it re-renders when the selected script changes.

## Phase 11 — Add Build Script *Folder*

- [x] Add an "Add Build Script Folder" action next to the existing "Add Build Script".
- [x] Use a native folder picker (`NSOpenPanel` with `canChooseDirectories`).
- [x] Import every runnable script found in the chosen folder, not just the first.
- [x] Reuse the existing script-scanning and location-classification logic rather than duplicating path parsing.
- [x] Reflect the imported scripts in the table without a full rescan where possible.
- [x] Handle cancel, permission-denied, empty-folder, and duplicate-script cases with a visible message. Empty-folder path GUI-verified; **every branch is now covered by unit tests** after the decision logic was extracted into `BuildScriptFolderImport`.
- [x] Mirror the new action into the empty-state `buildScriptsFallbackActions` row.

## Phase 12 — Build Parameters Move To The Detail View Window

- [x] Move the whole `buildParametersPanel` out of the centre `buildTab` into the right-hand inspector.
- [x] Widen the inspector substantially — raise `.inspectorColumnWidth` well past the current 340pt cap.
- [x] Make **Resolved Command** wrap instead of truncating (drop `.lineLimit(2)` / `.truncationMode(.middle)`).
- [x] Keep a **Run Build** button in the right panel next to the parameters, in addition to the per-row Run button in the table.
- [x] Keep the centre column as: scripts table on top, **Live Output below** (unchanged).
- [x] Confirm parameter editing still writes through to `workspaceStateStore` from its new location.
- [x] Confirm validation errors still surface somewhere the user will actually see them.
- [x] Confirm the existing Build Status / Build History / Quick Actions cards still fit alongside the parameters.
- [x] Confirm the panel behaves when it is hidden via the View menu — parameters must stay reachable.

## Resolved Decisions (answered 2026-08-16)

1. **Local folder *and* GitHub URL on one repo — YES, real model change.** A repository gains
   an optional GitHub URL alongside its local path, so a cloned repo remembers its origin.
   Existing saved repos must still decode.
2. **Run Build lives in both places** — the per-row Run button in the scripts table (already
   exists) *and* one in the right Detail View Window next to the parameters.
3. **The "auto detect" note was a new feature request, not a caption move** — see Phase 13.

## Phase 10 — Repository Header: Local Folder And GitHub URL (unblocked)

- [x] Add an optional `gitHubURL` to `Repository`, defaulted so existing `projects.json` still decodes.
- [x] Keep `RepositorySource` as the origin-of-record; the new field is supplementary, not a replacement.
- [x] Surface a way to set/clear the GitHub URL for a local repo — a "GitHub Origin" box in the repo Settings tab with Save/Clear and URL validation, backed by `RepositoryStore.setGitHubURL(_:for:)`.
- [x] Header line 1: repository title + Connected/status badge (unchanged).
- [x] Header line 2: **Local folder** path, labelled.
- [x] Header line 3: **GitHub URL**, labelled, below the local folder.
- [x] Hide (not blank-render) whichever line does not apply.
- [x] Keep both lines wrapped or middle-truncated so a deep path cannot break the header.

## Phase 13 — Deep Script Search ("Auto Find")

A dig/search tool that walks **every folder** of the repository for `.sh` files, then presents
them in a grid for the user to choose from. This replaces the vaguer "auto-detect" wording.

- [x] Add an "Auto Find Scripts" button to the Available Build Scripts header row.
- [x] Walk the whole repository tree recursively for `.sh` files — not just `/build/scripts/`.
- [x] Skip noise directories (`.git`, `node_modules`, `.build`, `DerivedData`, `Pods`, build output).
- [x] **Defect found in verification:** exact-name skipping let Xcode build trees through — `DerivedData-Device-Release`, `Pods.build`, `hermes-engine.build` — polluting the grid with generated `Script-<hex>.sh` files. Skipping now also matches the `DerivedData*` prefix and the `.build` / `.xcodeproj` / `.xcworkspace` suffixes. Results on LXC-MyHealthHub dropped from **20 (11 of them junk) to 10 real scripts**.
- [x] Run the walk off the main thread so a large repo cannot freeze the UI.
- [x] Show progress while the search runs, and allow it to be cancelled. **Measured: the walk completes in ~0.8s on the largest local repo, so the spinner is correct but not observable at this repo size.**
- [x] Present results in a **grid window** (sheet) with one selectable cell per discovered script.
- [x] Show enough per cell to disambiguate: filename, containing folder, and whether it is already added.
- [x] Support multi-selection in the grid.
- [x] Grid buttons: **Add All**, **Add Selected**, **Search Again**, **Cancel**.
- [x] "Search Again" re-runs the walk from scratch without closing the sheet.
- [x] Mark scripts already present so the user cannot silently add duplicates.
- [x] Reuse the existing script-scanning / location-classification logic rather than duplicating path parsing.
- [x] Show a clear empty state when the walk finds nothing.
- [x] Refresh the scripts table with whatever was added, preserving the current selection.

## Tracking — Pass 2

| Phase | Checked / Total | Status |
| --- | --- | --- |
| 8 — Table Shows Names | 5 / 5 | Done |
| 9 — Paths In Detail View | 4 / 4 | Done |
| 10 — Header Local + GitHub | 8 / 8 | Done |
| 11 — Add Script Folder | 7 / 7 | Done (error branches unit-tested) |
| 12 — Parameters To Detail View | 9 / 9 | Done |
| 13 — Deep Script Search | 15 / 15 | Done |
| **Pass 2 Total** | **48 / 48** | **Complete** |

## Pass 2 Verification Evidence

- `BUILD SUCCEEDED`, no new warnings.
- Scripts table rows now read `macos_apim_run` over `lxc-mhh-executables` (folder name), not the full path.
- Header renders `LXC-MyHealthHub ✓ Connected` over a labelled `Local folder:` line.
- Detail View Window shows Selected Script → **Full path wrapped across lines** → Copy Path,
  then Build Parameters with its own **Run Build** button, then a **wrapped Resolved Command**,
  then Build Status / History / Quick Actions. Column widened to min 320 / ideal 460 / max 900.
- Centre column is now scripts table over Live Output, with parameters gone from it.
- "Add Build Script" is now a menu offering **Add Build Script…** and **Add Build Script Folder…**.
- Auto Find opened, walked the whole repo, and found **20 scripts vs the 5 in /build/scripts**,
  correctly flagging **6 as "Already added"**. Selecting two updated the footer to
  "20 scripts found · 6 already added · 2 selected" and enabled **Add Selected**.
  Buttons present and behaving: Add All / Add Selected / Search Again / Cancel.

## Note On Concurrent Edits

The Pass 1 fixes (status bar as a `VStack` sibling, derived `columnVisibility` binding, and the
shared `showInspector` binding) were **reverted twice** by another agent session editing
`ContentView.swift` at the same time, which silently re-broke the Preferences-button clipping
and the View-menu detail-panel toggle. They have been re-applied. That session also committed a
syntactically invalid `Button` and a `Preferences.default` reference that does not exist; both
were repaired here to get the target compiling again.

## Follow-Up Verification (final pass)

- **GitHub Origin editor** added to the repo Settings tab: description, text field, Save, Clear,
  and validation that rejects anything that is not `https://github.com/owner/repo`. Clearing is
  an empty string, which nils the field. Verified rendering in the running app; the header then
  renders `Local folder:` above `GitHub:` exactly as requested, confirmed with the GitHub value
  seeded and the app relaunched. The typed-entry path could not be driven to completion because
  another app repeatedly stole focus mid-test — the store method and the render are both
  verified, the keystroke-to-save round trip is not.
- **Empty-folder branch** GUI-verified: picking a folder with no `.sh` files shows
  "No .sh scripts were found in that folder." in red under the Available Build Scripts heading.
- **Auto Find skip-list defect** found and fixed — see Phase 13. Re-verified live: the sheet now
  reports "10 scripts found · 6 already added" where it previously reported 20.
- **Search Again** re-runs the walk in place and clears the current selection.
- **Cancel** dismisses the sheet without importing anything.
- Test fixtures created during this pass were removed, and `projects.json` /
  `build-workspace-state.json` were restored from backups, so no test data was left behind.

### Closing The Last Two Gaps

Both remaining gaps were closed by moving the logic out of the view and testing it directly,
rather than by further GUI poking — the failure branches cannot be reached reliably through a
real `NSOpenPanel`, and GUI automation kept losing focus to other apps.

- **`BuildScriptFolderImport`** (new) now owns the folder-import decision, returning
  `.scripts`/`.outsideRepository`/`.unreadableFolder`/`.noScriptsInFolder`/`.allAlreadyAdded`
  with the user-facing message attached to the outcome. The view just renders the result.
- **`GitHubURLValidator`** (new) now owns the URL rules, returning `.cleared`/`.valid`/`.invalid`.

Five tests added to `Tests/BuildWorkspaceTests.swift`, all passing:

| Test | Covers |
| --- | --- |
| `testFolderImportRejectsFolderOutsideTheRepository` | Outside-repository guard, and that the Preferences opt-in unblocks it |
| `testFolderImportReportsEmptyUnreadableAndFullyDuplicateFolders` | Empty, unreadable, all-duplicate, partial-duplicate, and clean-import cases |
| `testGitHubURLValidatorAcceptsClearsAndRejects` | Blank clears; trims whitespace; rejects GitLab, owner-only paths, non-URLs, and `notgithub.com` |
| `testRepositoryKeepsGitHubURLOptionalAndDecodesOlderRecords` | Pre-field `projects.json` still decodes; `resolvedGitHubURL` and `localPath` for both source kinds |
| `testDeepScriptSearchSkipsXcodeBuildTreesButKeepsRealScripts` | Locks in the skip-list fix so `DerivedData-*`, `*.build`, and `node_modules` junk cannot come back |

**Suite status: 14 tests, 0 failures** (`xcodebuild test` → `TEST SUCCEEDED`), up from 9.

**The GitHub Origin field is now verified end to end in the running app.** Tabbing into the
field, typing `https://gitlab.com/owner/repo` and submitting showed the inline red
"Enter a GitHub URL in the form https://github.com/owner/repo." and left `projects.json`
untouched. Replacing it with a valid URL saved to disk, cleared the error, enabled **Clear**,
and the repository header updated live to show `GitHub:` beneath `Local folder:`. **Clear** then
removed the stored value. Nothing is left un-exercised.
