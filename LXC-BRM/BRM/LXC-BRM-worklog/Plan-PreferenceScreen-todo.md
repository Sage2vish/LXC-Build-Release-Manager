# Preferences Screen — Plan & Checklist

Sources:
- Initial concept mockup ("What I'd Like To Have In Preferences" / "Preferences – How It Will Look" / "How Preferences Will Open") — established the modal-dialog decision and an early 6-section field list.
- Section taxonomy supplied 2026-08-16, refining those 6 sections into 7 (splits "UI/Display" into "Appearance" and pulls notification toggles into their own tab).
- **Screen 1 — General tab**, high-fidelity mockup shown inside the actual app chrome (sidebar, status bar, right panel — matches what's already built). Superseded the early General field guesses with the real field list below.
- **Screen 2 — Repositories tab**, same fidelity. Superseded the early Repositories field guesses.
- **Screen 3 — Build Execution tab**, same fidelity. Superseded the early Build Execution field guesses.
- **Screen 4 — Logs & Console tab**, same fidelity. Superseded the early Logs & Console field guesses.

Image files: `assets/Preference-Screen-1.png` through `assets/Preference-Screen-4.png` — not yet on disk, and this isn't something I'm choosing to skip: a chat-pasted image reaches me only as something I can look at, never as file bytes, and none of my tools can export it. There is no tool call in my toolset that turns a pasted image into a saved file — I checked your clipboard and Desktop/Downloads for a match and found nothing there either. The only way these land in `assets/` is you saving them from Finder (drag the image out of the chat, or right-click → Save Image As) under the exact names above. Once they're there I'll use them automatically — I'm not re-checking or re-asking, just noting it stays true each round. Everything else below is written directly from reading each screen.

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

### 05 🎨 Appearance
- App Theme: Light / Dark / System

### 06 🔔 Notifications
- Show toast notifications for build events
- Show build summary notification on completion

### 07 🛠 Advanced
- Allow script execution from outside `/build/scripts` (default off)
- Enable verbose internal logging (default off)
- Restore Defaults (reset all settings to recommended defaults)

## Window Mechanics

- Modal, centered over the main window (SwiftUI `.sheet` presented from `ContentView`; the sidebar's gear button switches from today's `openSettings()` to presenting this sheet).
- Left tab rail (icon + label) for the 7 sections above; selecting one shows its fields on the right, matching the mockup's General/Repository/... layout.
- Bottom bar: "Restore Defaults" on the left; "Cancel" / "Save" on the right, Save is the prominent action.
- Draft/commit editing: edits apply to a local draft; only "Save" commits to the persisted store, "Cancel" discards.
- Settings apply immediately after Save where possible (theme, font, etc.).
- Persisted at `~/Library/Application Support/LXC-BRM/preferences.json` — keeping the existing `LXC-BRM` app-support folder name (the mockup's note said `BuildManager`; staying consistent with `RepositoryStore`/`BuildHistoryStore`, which already use `LXC-BRM`).

## Checklist

### Data & persistence
- [ ] `Preferences` model covering every field above, Codable
- [ ] `PreferencesStore` (ObservableObject; load/save JSON to `~/Library/Application Support/LXC-BRM/preferences.json`)
- [ ] Recommended-defaults constant (System theme, Build tab, 30-day retention, `/bin/bash`, 2 concurrent builds, SF Mono 13)

### Window & navigation
- [ ] Modal sheet replacing the current `Settings` scene `PreferencesView`
- [ ] Left tab rail: General / Repositories / Build Execution / Logs & Console / Appearance / Notifications / Advanced, each with its icon
- [ ] Bottom bar: Restore Defaults (left), Cancel / Save (right)
- [ ] Sidebar gear button opens this sheet (instead of `openSettings()`)
- [ ] Draft/commit editing: changes only take effect on Save; Cancel discards them

### 01 General
- [ ] Launch at login toggle — wire into a login-item registration (`SMAppService` on macOS 13+)
- [ ] Restore last opened repository on launch toggle — wire into `RepositoryStore` init to re-select the last active repo
- [ ] Default tab on launch dropdown — wire into `RepositoryDetailView`'s initial `selectedTab`
- [ ] Remember recent repositories toggle — wire into whether `RepositoryStore` persists at all (off = session-only)
- [ ] Maximum recent repositories field — wire into the sidebar's `recentRepositories` cap (currently hardcoded to 5) — **shared with Repositories tab, see open question**
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
- [ ] Maximum recent repositories field — same field/storage as General's copy; **implementation note:** back both UI fields with one shared preference, not two
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
- [ ] App Theme control (Light/Dark/System) — wire to actual app appearance (currently always follows system with no override)

### 06 Notifications
- [ ] Toast notifications toggle — no toast/notification system exists yet; build the minimal version needed to honor this toggle
- [ ] Build summary notification toggle — same, groundwork until a notification system exists

### 07 Advanced
- [ ] Allow script execution from outside `/build/scripts` toggle — wire into `BuildScriptScanner`
- [ ] Verbose internal logging toggle — groundwork only, no internal debug logging exists yet
- [ ] Restore Defaults action — resets the draft to recommended defaults (not saved until Save is pressed)

### Polish
- [ ] Preferences load and apply on app launch (theme, default tab, etc.)

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Data & persistence | 0 / 3 | Open |
| Window & navigation | 0 / 5 | Open |
| 01 General | 0 / 10 | Open |
| 02 Repositories | 0 / 9 | Open |
| 03 Build Execution | 0 / 10 | Open |
| 04 Logs & Console | 0 / 15 | Open |
| 05 Appearance | 0 / 1 | Open (pending Screen 5) |
| 06 Notifications | 0 / 2 | Open (pending Screen 6) |
| 07 Advanced | 0 / 3 | Open (pending Screen 7) |
| Polish | 0 / 1 | Open |
| **Total** | **0 / 59** | **Not started** |

## Screens Received

| Screen | Tab | Status |
| --- | --- | --- |
| 1 | General | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 2 | Repositories | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 3 | Build Execution | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 4 | Logs & Console | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 5 | Appearance | ⏳ Waiting — fields below are still the early guesses from the concept mockup |
| 6 | Notifications | ⏳ Waiting — same |
| 7 | Advanced | ⏳ Waiting — same |

## Notes / Open Questions

1. Several toggles (Check for updates, toast/summary notifications, verbose logging, update channel, language) don't have a system to hook into yet — built as inert/stored-only settings first, wired up when the underlying feature exists. Flagged per item above so nothing is silently faked as "working."
2. **Duplicate field across tabs**: "Maximum recent repositories" appears on both the General and Repositories screens. Plan is to back both fields with the *same* stored value rather than two separate ones — worth confirming this is intentional (a shared setting shown in two places) rather than two different limits.
3. **Two similar-but-different restore toggles**: General's "Restore last opened repository on launch" (singular, the one active repo) vs. Repositories' "Automatically restore last opened repositories" (plural, the full previous set). Kept both since they read as genuinely different behaviors, but flagging in case that's not the intent.
4. GitHub access moved from an inline token field (early mockup) to a "Configure…" button opening a sub-sheet (Screen 2) — plan follows the newer screen.
5. **Another duplicate field**: "Logs directory (inside /build)" appears on both the Repositories tab (Screen 2) and the Logs & Console tab (Screen 4), same default `logs`. Same resolution as note 2 — one shared stored value, shown in both places.
6. **Shell default mismatch**: Screen 3's mockup defaults "Default shell" to `/bin/zsh`; the app's `BuildRunner` currently hardcodes `/bin/bash`. Worth confirming which is the intended default before wiring this field — flagged rather than silently picked.
7. Storage path: keeping `~/Library/Application Support/LXC-BRM/preferences.json` instead of the early mockup's `BuildManager/` folder name, for consistency with the app's existing stores.
8. This supersedes the placeholder `PreferencesView`/`Settings` scene built earlier today (2026-08-16); that code will be replaced, not kept alongside.
