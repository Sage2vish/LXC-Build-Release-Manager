# Preferences Screen — Plan & Checklist

Sources:
- Initial concept mockup ("What I'd Like To Have In Preferences" / "Preferences – How It Will Look" / "How Preferences Will Open") — established the modal-dialog decision and an early 6-section field list.
- Section taxonomy supplied 2026-08-16, refining those 6 sections into 7 (splits "UI/Display" into "Appearance" and pulls notification toggles into their own tab).
- **Screen 1 — General tab**, high-fidelity mockup shown inside the actual app chrome (sidebar, status bar, right panel — matches what's already built). Superseded the early General field guesses with the real field list below.
- **Screen 2 — Repositories tab**, same fidelity. Superseded the early Repositories field guesses.
- **Screen 3 — Build Execution tab**, same fidelity. Superseded the early Build Execution field guesses.
- **Screen 4 — Logs & Console tab**, same fidelity. Superseded the early Logs & Console field guesses.
- **Screen 5 — Appearance tab**, same fidelity. Superseded the early Appearance field guess (was a single "App Theme" line; the real tab is much larger).
- **Screen 6 — Notifications tab**, same fidelity. Superseded the early Notifications field guess.
- **Screen 7 — Advanced tab**, same fidelity. Superseded the early Advanced field guess. **All 7 tabs now covered.**

Image files (naming convention: `Preference-Screen-N-<TabName>.png`):
- `assets/Preference-Screen-1-General.png`
- `assets/Preference-Screen-2-Repositories.png`
- `assets/Preference-Screen-3-BuildExecution.png`
- `assets/Preference-Screen-4-LogsConsole.png`
- `assets/Preference-Screen-5-Appearance.png`
- `assets/Preference-Screen-6-Notifications.png`
- `assets/Preference-Screen-7-Advanced.png`

None are on disk yet. This is a hard tool limitation: a chat-pasted image reaches me only as something I can look at, never as file bytes, and nothing in my toolset exports it. The only way these land in `assets/` is saving them from Finder (drag the image out of the chat, or right-click → Save Image As) under the exact names above. Everything else below is written directly from reading each screen.

This is a **plan document**, not a duplicate todo list — the single active todo file is still `todo-2026-08-16.md`. This file holds the detailed design + checklist for one feature (the Preferences screen); the master todo links to it as one line item so tracking still has one home.

## Decision: How Preferences Opens

**Option 1 — Modal Dialog (Center)**, per the reference image and the user's explicit pick. Opens as a modal dialog centered over the main window; focus stays on Preferences until Save or Cancel. This **replaces** the placeholder `PreferencesView` / `Settings` scene (Cmd+,) built earlier today, which was only a stand-in before this reference existed.

## Section Taxonomy (final, 7 tabs)

| # | Tab | Covers |
| --- | --- | --- |
| 01 | ⚙️ General | Overall application behaviour |
| 02 | 📁 Repositories | Repository discovery, opening and persistence |
| 03 | ▶️ Build Execution | How scripts/builds are executed |
| 04 | 📄 Logs & Console | Logging, retention and live console behaviour |
| 05 | 🎨 Appearance | Light/dark/system theme and UI presentation |
| 06 | 🔔 Notifications | Build success/failure/cancel notifications |
| 07 | 🛠 Advanced | Technical, debugging and reset options |

Mapping from the mockup's original fields into these 7 tabs (theme moved out of General into its own Appearance tab; toast/summary notifications moved out of General/Build Execution into Notifications; timeout/kill-process-tree kept in Build Execution since they're execution behavior, not debugging):

### 01 ⚙️ General — *finalized from Screen 1*
- Launch Build Manager at login (off by default) — "Automatically start the application when you log in to macOS."
- Restore last opened repository on launch (on) — "Open the last repository you were working with."
- Default tab on launch — dropdown, default "Build" — "Select which tab to show when Build Manager starts."
- Remember recent repositories (on) — "Store recently opened repositories for quick access."
- Maximum recent repositories — stepper, default 10 — "Number of repositories to keep in the Recent list." *(also appears on the Repositories tab in Screen 2 — see open question below.)*
- Confirm before quitting while a build is running (on) — "Prevent accidental quit when a build process is active."
- Confirm before clearing history or logs (on) — "Ask for confirmation before clearing history or deleting logs."
- Check for updates automatically (on) — "Periodically check for updates in the background."
- Update channel — dropdown, default "Stable (Recommended)" — "Choose how you want to receive updates."
- Language — dropdown, default "System Default" — "Restart required to apply language changes."

### 02 📁 Repositories — *finalized from Screen 2*
- Default repository root detection (on) — "When opening a folder, automatically look for a /build directory."
- Default `/build` folder name — text field, default `/build` — "Folder name that contains scripts, logs, and project config."
- Scripts directory (inside `/build`) — text field, default `scripts` — "Relative path where build scripts are located." *(has an info tooltip)*
- Logs directory (inside `/build`) — text field, default `logs` — "Relative path where build logs are stored." *(has an info tooltip)*
- Scan subdirectories for `/build` folders (on) — "Also detect /build in subfolders when opening a repository." *(mono-repo support)*
- Maximum number of Recent Repositories — stepper, default 10 — "Limit how many repositories are kept in the Recent list." *(duplicate of the General tab's field — see open question below.)*
- Automatically restore last opened repositories (on) — "Re-open the repositories that were open in the previous session." *(plural — restores every repo that was open, distinct from General's "restore last opened repository," which is the single active one.)*
- GitHub access (optional) — "Configure…" button opening a sub-sheet — "Used to fetch private repositories and metadata." *(this is where the earlier GitHub Token field lives — as a Configure flow, not an inline field.)*
- Auto-detect repositories on startup (on) — "Check default locations for repositories when app launches."

### 03 ▶️ Build Execution — *finalized from Screen 3*
- Default shell — dropdown, default `/bin/zsh` — "Shell used to run build scripts." *(mockup's default differs from the app's current hardcoded `/bin/bash` — see open question below)*
- Working directory — dropdown, default "Repository Root" — "Directory where scripts are executed."
- Environment variables — "Edit Variables…" button opening a sub-sheet — "Set default environment variables for all builds."
- Max concurrent builds — stepper, default 2 — "Maximum number of builds that can run at the same time."
- Build timeout — dropdown, default "60 min" — "Maximum time allowed for a build to run."
- Terminate child processes on Stop (on) — "Kill all child processes when a build is stopped."
- Preserve partial output on cancellation (on) — "Keep output generated before a build is cancelled."
- Automatically save logs (on) — "Save log file after a build completes."
- Prevent macOS sleep while a build is running (on) — "Keep system awake during long running builds."
- Default behavior after build completes — dropdown, default "Stay on Output" — "What to do when a build finishes."

### 04 📄 Logs & Console — *finalized from Screen 4*

**Log Storage**
- Save build logs to disk automatically (on) — "Every build run will be saved to a log file."
- Default logs directory (inside `/build`) — text field + folder-browse icon, default `logs` — "Relative path where build logs are stored." *(duplicate of the Repositories tab's "Logs directory" field — see open question below)*
- Log retention period — dropdown, default "30 days" — "Automatically delete logs older than the selected period."
- Maximum log file size — dropdown, default "100 MB" — "Rotate/create a new log when size limit is reached."
- Maximum number of stored logs — stepper, default 100 — "Oldest logs will be removed when limit is exceeded."

**Log Format**
- Timestamp format — dropdown, default `[14:32:45]` — "Format used for timestamps in logs and console."
- Encoding — dropdown, default "UTF-8" — "Character encoding for log files."

**Console / Output**
- Console font — "SF Mono Regular" + "Change…" button — "Font used in the live output and log viewer."
- Font size — stepper, default 13 — "Adjust the font size for console text."
- Line spacing — stepper, default 1.2 — "Space between lines in the console."
- Word wrap (on) — "Wrap long lines in the console and log viewer."
- Auto-scroll to bottom (on) — "Automatically scroll to the latest output."
- Show line numbers (on) — "Show line numbers in log viewer."
- Colorize output (on) — "Highlight INFO / WARN / ERROR / SUCCESS."
- Default log filter — dropdown, default "All Lines" — "Applied when opening a log."
- Search is case sensitive (off) — "Case sensitive search in logs."

### 05 🎨 Appearance — *finalized from Screen 5*
- Theme — card picker: Light / Dark / System, default Light
- UI Density — dropdown, default "Comfortable" — "Adjust the spacing and size of elements in the app."
- Sidebar Width — dropdown, default "Medium (280px)" — "Choose the width of the left sidebar."
- Text Size — dropdown, default "Default (100%)" — "Adjust the base text size in the app."
- Accent Color — swatch picker (blue selected, plus purple/green/orange/red/teal/gray) + "Custom…" — "Choose the accent color used for highlights and actions."
- Show animations (on) — "Enable subtle animations for a smoother experience."
- Round window corners (on) — "Use rounded corners for windows and panels."
- Reduce transparency (off) — "Minimize transparency effects for better readability."
- Use system font (San Francisco) (on) — "Use macOS system font for a native look."

### 06 🔔 Notifications — *finalized from Screen 6*

**Notification Settings**
- Enable build notifications (on) — "Show notifications for build events." *(master toggle for the whole tab)*
- Build Started (on) — "Notify when a build starts."
- Build Succeeded (on) — "Notify when a build completes successfully."
- Build Failed (on) — "Notify when a build fails."
- Build Cancelled / Stopped (on) — "Notify when a build is cancelled or stopped."
- Long Running Build Completed (on) — "Notify when a long running build finishes."

**Notification Behavior**
- Notify only when Build Manager is not in focus (on) — "Avoid interrupting you while you're already in the app."
- Play sound — dropdown, default "Glass" — "Play a system sound with notifications."
- Show notification duration — dropdown, default "5 seconds" — "How long notifications stay visible."

**Advanced (Optional)**
- Group multiple notifications (off) — "Combine multiple events into a single notification."

### 07 🛠 Advanced — *finalized from Screen 7*

**Build & Script Behavior**
- Allow scripts outside `/build/scripts` (off) — "Allow executing scripts from anywhere in the repository."
- Custom build timeout, overrides per-build timeout — stepper, default 0 min ("0 = no timeout") — a **global ceiling**, distinct from Build Execution's per-build "Build timeout" dropdown (Screen 3) — see open question below
- Detect executable files automatically (on) — "Treat files with exec permission as runnable scripts."
- Terminate process tree on Stop (on) — "Kill all child processes and their children when build is stopped." *(duplicate of Build Execution's "Terminate child processes on Stop" — see open question below)*

**Logging & Diagnostics**
- Verbose / Debug logging (off) — "Enable detailed internal logging for troubleshooting."
- Log internal diagnostics to file (on) — "Save Build Manager diagnostics to disk."
- Diagnostics log location — text field + folder icon, default `~/Library/Logs/BuildManager/`
- "Run Diagnostics Report…" button — "Collect system and configuration info for troubleshooting."

**GitHub & Network**
- GitHub API diagnostics — "Run GitHub Diagnostics…" button — "Check GitHub API connectivity and token status."
- GitHub rate limit alerts — dropdown, default "Warn me at 20%" — "Warn when API rate limit is low."

**Data & Maintenance**
- Open Build Manager data directory — "Open Folder" button
- Open `projects.json` — "Open File" button (opens in the user's default editor)
- Clear repository metadata cache — "Clear Cache" button — "Repositories will be re-scanned."
- Clear build history — "Clear History" button — "Remove all build history from this machine."
- Reset all warnings — "Reset Warnings" button — "Reset all 'Don't show again' warnings."

**Danger Zone**
- Restore All Defaults — destructive red button in a highlighted "Danger Zone" panel — "Reset all preferences to default values." *(distinct from the bottom-bar "Restore Defaults" — see open question below)*

## Window Mechanics

- Modal, centered over the main window (SwiftUI `.sheet` presented from `ContentView`; the sidebar's gear button switches from today's `openSettings()` to presenting this sheet).
- Left tab rail (icon + label) for the 7 sections above; selecting one shows its fields on the right, matching the mockup's General/Repository/... layout.
- Bottom bar: "Restore Defaults" on the left; "Cancel" / "Save" on the right, Save is the prominent action.
- Draft/commit editing: edits apply to a local draft; only "Save" commits to the persisted store, "Cancel" discards.
- Settings apply immediately after Save where possible (theme, font, etc.).
- Persisted at `~/Library/Application Support/LXC-BRM/preferences.json` — keeping the existing `LXC-BRM` app-support folder name (the mockup's note said `BuildManager`; staying consistent with `RepositoryStore`/`BuildHistoryStore`, which already use `LXC-BRM`).

## Checklist

Every field in every tab below now exists as an editable, `preferences.json`-persisted control in `PreferencesView.swift` (draft/Save/Cancel/Restore Defaults all working, `BUILD SUCCEEDED`). A box only flips to `[x]` once the field also *does something* in the app — the UI existing is necessary but not sufficient, per this file's own rule at the top. Three fields are wired end-to-end and checked below: Theme, Default Tab on Launch, and Maximum Recent Repositories.

### Data & persistence
- [x] `Preferences` model covering every field above, Codable — `App/Models/Preferences.swift`
- [x] `PreferencesStore` (ObservableObject; load/save JSON to `~/Library/Application Support/LXC-BRM/preferences.json`) — `App/Services/PreferencesStore.swift`
- [x] Recommended-defaults constant — `Preferences.recommendedDefaults`, used by both initial load and "Restore Defaults"

### Window & navigation
- [x] Modal sheet replacing the current `Settings` scene `PreferencesView` — `Settings` scene removed from `LXC_BRMApp.swift`, sheet presented from `ContentView`
- [x] Left tab rail: General / Repositories / Build Execution / Logs & Console / Appearance / Notifications / Advanced, each with its icon
- [x] Bottom bar: Restore Defaults (left), Cancel / Save (right)
- [x] Sidebar gear button opens this sheet (instead of `openSettings()`)
- [x] Draft/commit editing: `@State private var draft` initialized from the store; Save calls `store.save(draft)`, Cancel just dismisses

### 01 General
- [ ] Launch at login toggle — wire into a login-item registration (`SMAppService` on macOS 13+)
- [ ] Restore last opened repository on launch toggle — wire into `RepositoryStore` init to re-select the last active repo
- [x] Default tab on launch dropdown — wired into `RepositoryDetailView`'s initial `selectedTab` via `DetailTab.init(_:DefaultLaunchTab)`
- [ ] Remember recent repositories toggle — wire into whether `RepositoryStore` persists at all (off = session-only)
- [x] Maximum recent repositories field — wired into the sidebar's `recentRepositories` cap (`ContentView.recentRepositories` now reads `preferencesStore.preferences.maxRecentRepositories`) — **shared with Repositories tab's copy, same stored value as decided in the open question**
- [ ] Confirm-before-quitting-during-build toggle — wire into an `NSApplication` termination check against any running `BuildRunner`
- [ ] Confirm-before-clearing toggle (groundwork — no "clear logs/history" action exists yet to gate)
- [ ] Check for updates automatically toggle (storage only — no update-checking mechanism exists yet; inert until Phase 7 tackles distribution)
- [ ] Update channel dropdown (storage only, same caveat as above)
- [ ] Language dropdown (storage only — app isn't localized yet)

### 02 Repositories
- [ ] Default repository root detection toggle — wire into `BuildScriptScanner` (currently always on/hardcoded)
- [ ] Default `/build` folder name field — wire into `BuildScriptScanner.scanLocal`/`scanGitHub` (currently hardcoded to `"build"`)
- [ ] Scripts directory field — wire into `BuildScriptScanner` (currently hardcoded to `"scripts"`)
- [ ] Logs directory field — wire into `LogFileService.logsDirectoryURL` (currently hardcoded to `"build/logs"`)
- [ ] Scan subdirectories for `/build` folders toggle — wire into `BuildScriptScanner` for mono-repo support
- [x] Maximum recent repositories field — same field/storage as General's copy, wired (see 01 General)
- [ ] Automatically restore last opened repositories toggle — wire into `RepositoryStore` to reopen the full previous set, not just one
- [ ] GitHub access "Configure…" sub-sheet — token entry (secure), wire into `BuildScriptScanner.scanGitHub` to raise API rate limits
- [ ] Auto-detect repositories on startup toggle

### 03 Build Execution
- [ ] Default shell dropdown — wire into `BuildRunner.start` (currently hardcoded to `/bin/bash`; mockup default is `/bin/zsh` — resolve before implementing, see open question)
- [ ] Working directory dropdown (Repository Root / Custom) — wire into `BuildRunner.start`'s `currentDirectoryURL`
- [ ] Environment Variables "Edit Variables…" sub-sheet (key=value pairs) — wire into `Process.environment`
- [ ] Max concurrent builds stepper — wire into `BuildRunnerRegistry` (currently unlimited concurrent runners)
- [ ] Build timeout dropdown — wire into `BuildRunner` (auto-cancel after N minutes; 0/off = no limit)
- [ ] Terminate child processes on Stop toggle — wire into `BuildRunner.cancel()` (kill process tree, not just the top-level process)
- [ ] Preserve partial output on cancellation toggle — `BuildRunner` already does this unconditionally; exposing as a toggle means adding a "discard partial output" code path when off
- [ ] Automatically save logs toggle — `LogFileService.write` already runs unconditionally on every finish; exposing as a toggle means skipping the write when off
- [ ] Prevent macOS sleep while a build is running toggle — wire into `IOKit`/`ProcessInfo.beginActivity(options: .idleSystemSleepDisabled, ...)` while `BuildRunner.isRunning`
- [ ] Default behavior after build completes dropdown (e.g. "Stay on Output") — wire into `RepositoryDetailView`'s tab-switch behavior on build completion

### 04 Logs & Console
- [ ] Save build logs to disk automatically toggle — `LogFileService.write` currently runs unconditionally; off means skip the write
- [ ] Default logs directory field — wire into `LogFileService.logsDirectoryURL` (currently hardcoded `"build/logs"`); shared value with Repositories tab's copy, see open question
- [ ] Log retention period dropdown — wire into a cleanup pass over `/build/logs/` (doesn't exist yet)
- [ ] Maximum log file size dropdown — groundwork only, no size capping/rotation exists yet
- [ ] Maximum number of stored logs stepper — groundwork only, no oldest-log eviction exists yet
- [ ] Timestamp format dropdown — wire into `displayLines`/`LogFileService`'s `DateFormatter` (currently hardcoded `HH:mm:ss`)
- [ ] Encoding dropdown — wire into `LogFileService` read/write (currently hardcoded `.utf8`)
- [ ] Console font + size fields — wire into `LogPane`'s monospaced text (currently hardcoded `.caption`/system monospaced)
- [ ] Line spacing field — wire into `LogPane`'s `LazyVStack` spacing
- [ ] Word wrap toggle — new feature in `LogPane` (currently lines don't wrap)
- [ ] Auto-scroll to bottom toggle — new feature in `LogPane` (currently no auto-scroll while live output streams)
- [ ] Show line numbers toggle — new feature in `LogPane`
- [ ] Colorize output toggle — new feature in `LogPane` (color by INFO/WARN/ERROR/SUCCESS keyword, distinct from the existing search-match highlight)
- [ ] Default log filter dropdown — wire into `LogPane`'s existing `LogFilter` enum as its initial value instead of always starting at `.all`
- [ ] Search-is-case-sensitive toggle — wire into `LogPane`'s search (currently always `localizedCaseInsensitiveContains`)

### 05 Appearance
- [x] Theme card picker (Light/Dark/System) — wired via `ContentView.preferredColorScheme`, mapping `.light`/`.dark` to a real override and `.system` to `nil` (today's default-follows-system behavior, unchanged for that case)
- [ ] UI Density dropdown — new concept, no density-aware spacing exists yet across the app's views
- [ ] Sidebar Width dropdown — wire into `NavigationSplitView`'s sidebar column width (currently unset/default)
- [ ] Text Size dropdown — new concept, no app-wide dynamic type scaling exists yet
- [ ] Accent Color swatch picker + Custom — wire into `.tint()`/`AccentColor` asset (currently uses the system accent color only)
- [ ] Show animations toggle — groundwork; app currently uses SwiftUI's implicit animations without a global on/off
- [ ] Round window corners toggle — groundwork; no custom window-corner styling exists yet
- [ ] Reduce transparency toggle — groundwork; app currently uses standard `.bar`/`.background` materials with no transparency override
- [ ] Use system font toggle — groundwork; app already uses the system font everywhere by default, so "on" is a no-op and "off" needs a real alternate-font path to mean anything

### 06 Notifications
- [ ] `UNUserNotificationCenter` integration — nothing exists yet; this whole tab is groundwork until real macOS notifications are wired into `BuildRunner`'s lifecycle (start/success/fail/cancel/long-running)
- [ ] Enable build notifications master toggle — gates all of the below
- [ ] Per-event toggles (Started / Succeeded / Failed / Cancelled / Long Running) — wire into `BuildRunner.start`/`finish` posting distinct notification types
- [ ] "Notify only when not in focus" toggle — wire into `NSApplication.shared.isActive`
- [ ] Play sound dropdown — wire into `UNNotificationSound`
- [ ] Show notification duration dropdown — macOS controls this at the system level (Notification Center settings), not per-app; flag as likely **not implementable** as a real app preference, only informational, unless there's a custom in-app toast instead of system notifications
- [ ] Group multiple notifications toggle — wire into `UNNotificationRequest` threading/grouping

### 07 Advanced
- [ ] Allow scripts outside `/build/scripts` toggle — wire into `BuildScriptScanner`
- [ ] Global custom build timeout stepper — wire into `BuildRunner` as a ceiling that overrides Build Execution's per-build timeout when non-zero
- [ ] Detect executable files automatically toggle — wire into `BuildScriptScanner` (currently only matches `.sh` by extension, not exec permission)
- [ ] Terminate process tree on Stop toggle — same underlying setting as Build Execution's "Terminate child processes on Stop"; back both fields with one shared value, don't build two
- [ ] Verbose / Debug logging toggle — groundwork only, no internal debug logging exists yet
- [ ] Log internal diagnostics to file toggle + location field — groundwork; no diagnostics-log writer exists yet
- [ ] "Run Diagnostics Report…" button — new feature, collects system/app/config info into a shareable report
- [ ] "Run GitHub Diagnostics…" button — wire into `BuildScriptScanner.scanGitHub`'s connectivity path as a manual health check
- [ ] GitHub rate limit alerts dropdown — wire into the GitHub API response headers (`X-RateLimit-Remaining`) once the scanner reads them
- [ ] Open Build Manager data directory button — `NSWorkspace.shared.open` on `~/Library/Application Support/LXC-BRM/`
- [ ] Open `projects.json` button — `NSWorkspace.shared.open` on the file (note: `projects.json` today is the static config template in the repo, not a live app file — see open question)
- [ ] Clear repository metadata cache button — no metadata cache exists yet to clear (current scans are always live, not cached)
- [ ] Clear build history button — wire into `BuildHistoryStore` (needs a real "clear" method; doesn't exist yet)
- [ ] Reset all warnings button — no "don't show again" warning system exists yet
- [ ] Restore All Defaults (Danger Zone) — immediate destructive action distinct from the per-tab bottom-bar "Restore Defaults" (draft-only, needs Save) — see open question below

### Polish
- [ ] Preferences load and apply on app launch (theme, default tab, etc.)

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Data & persistence | 3 / 3 | Done |
| Window & navigation | 5 / 5 | Done |
| 01 General | 2 / 10 | In Progress |
| 02 Repositories | 1 / 9 | In Progress |
| 03 Build Execution | 0 / 10 | Open (UI built, not wired) |
| 04 Logs & Console | 0 / 15 | Open (UI built, not wired) |
| 05 Appearance | 1 / 9 | In Progress |
| 06 Notifications | 0 / 7 | Open (UI built, not wired) |
| 07 Advanced | 0 / 15 | Open (UI built, not wired) |
| Polish | 0 / 1 | Open |
| **Total** | **12 / 84** | **PreferencesView built for all 7 tabs; 3 fields wired into real app behavior** |

## Screens Received

| Screen | Tab | Status |
| --- | --- | --- |
| 1 | General | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 2 | Repositories | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 3 | Build Execution | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 4 | Logs & Console | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 5 | Appearance | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 6 | Notifications | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 7 | Advanced | ✅ Read and incorporated (image not yet saved to `assets/`) — **all screens done** |

## Notes / Open Questions

1. Several toggles (Check for updates, toast/summary notifications, verbose logging, update channel, language) don't have a system to hook into yet — built as inert/stored-only settings first, wired up when the underlying feature exists. Flagged per item above so nothing is silently faked as "working."
2. **Duplicate field across tabs**: "Maximum recent repositories" appears on both the General and Repositories screens. Plan is to back both fields with the *same* stored value rather than two separate ones — worth confirming this is intentional (a shared setting shown in two places) rather than two different limits.
3. **Two similar-but-different restore toggles**: General's "Restore last opened repository on launch" (singular, the one active repo) vs. Repositories' "Automatically restore last opened repositories" (plural, the full previous set). Kept both since they read as genuinely different behaviors, but flagging in case that's not the intent.
4. GitHub access moved from an inline token field (early mockup) to a "Configure…" button opening a sub-sheet (Screen 2) — plan follows the newer screen.
5. **Another duplicate field**: "Logs directory (inside /build)" appears on both the Repositories tab (Screen 2) and the Logs & Console tab (Screen 4), same default `logs`. Same resolution as note 2 — one shared stored value, shown in both places.
6. **Shell default mismatch**: Screen 3's mockup defaults "Default shell" to `/bin/zsh`; the app's `BuildRunner` currently hardcodes `/bin/bash`. Worth confirming which is the intended default before wiring this field — flagged rather than silently picked.
7. **Theme override reverses an earlier decision.** Screen 5's Light/Dark/System picker means the app needs a manual appearance override — but the app was deliberately built earlier today to *always* follow the system appearance, per explicit instruction ("the dark or bright has to be the system default"), which removed a hardcoded dark background specifically to achieve that. This isn't a contradiction to silently resolve: implementing the theme picker is the right call (it's what's being asked for now, and "System" as the default still satisfies the earlier instruction), just flagging that it's a deliberate reversal of "no in-app override," not an oversight.
8. Storage path: keeping `~/Library/Application Support/LXC-BRM/preferences.json` instead of the early mockup's `BuildManager/` folder name, for consistency with the app's existing stores.
9. This supersedes the placeholder `PreferencesView`/`Settings` scene built earlier today (2026-08-16); that code will be replaced, not kept alongside.
10. **Third duplicate: "terminate process tree on Stop."** Appears near-verbatim on both Build Execution (Screen 3) and Advanced (Screen 7). Same resolution as notes 2 and 5 — one shared stored value, shown in both places, not two independently-tracked settings.
11. **Two different "timeout" fields that are NOT duplicates.** Build Execution's "Build timeout" (Screen 3, default 60 min) is a per-build default; Advanced's "Custom build timeout (overrides per-build timeout)" (Screen 7, default 0/no limit) is described as a global ceiling. Kept as two distinct fields since the mockup is explicit about the override relationship — worth confirming that reading is right before implementing.
12. **Two different "Restore Defaults" actions that are NOT duplicates.** The bottom bar's "Restore Defaults" (present on every tab) resets the current draft — not applied until Save. Advanced's "Restore All Defaults" sits in a red "Danger Zone" panel, styled as an immediate destructive action. Treating these as genuinely different: one is undo-able (Cancel discards it), the other reads as applying immediately. Needs a real confirmation dialog before wiring, given the styling explicitly calls it dangerous.
13. **"Open projects.json" assumes a live file that doesn't exist yet.** Today, `projects.json` is a static example/template committed in `LXC-BRM-build-release/`, not a file the running app reads or writes. This button implies the app should have its own live `projects.json`-equivalent — needs a decision on whether to point this at the existing repo file (read-only reference) or introduce a new live one (more consistent with the rest of Advanced's "Data & Maintenance" framing, but a bigger change).
