# Preferences Screen — Plan & Checklist

Sources:
- Initial concept mockup ("What I'd Like To Have In Preferences" / "Preferences – How It Will Look" / "How Preferences Will Open") — established the modal-dialog decision and an early 6-section field list.
- Section taxonomy supplied 2026-08-16, refining those 6 sections into 7 (splits "UI/Display" into "Appearance" and pulls notification toggles into their own tab).
- **Screen 1 — General tab**, high-fidelity mockup shown inside the actual app chrome (sidebar, status bar, right panel — matches what's already built). Superseded the early General field guesses with the real field list below.
- **Screen 2 — Repositories tab**, same fidelity. Superseded the early Repositories field guesses.

Image files: `assets/Preference-Screen-1.png` and `assets/Preference-Screen-2.png` — not yet on disk. Pasted-chat images can't be exported to a file by me; save them from Finder (drag or Save Image As) into `LXC-BRM/BRM/LXC-BRM-worklog/assets/` under those exact names and this plan will pick them up. Everything else below is written directly from reading both screens.

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

### 03 ▶️ Build Execution
- Default Shell: `/bin/bash` / `zsh` / `sh`
- Max Concurrent Builds
- Default Working Directory: Repository Root / Custom
- Environment Variables (key=value pairs)
- Pass stdout/stderr to log file (always on by default — shown locked/read-only)
- Custom build timeout (minutes), 0 = No limit
- Kill process tree on cancel (recommended, default on)

### 04 📄 Logs & Console
- Default Log Retention (days) — default 30
- Maximum Log File Size (MB) — default 100
- Compress old logs automatically
- Default Encoding: UTF-8 / System
- Open logs in external editor
- Default Search: Match Case / Whole Word
- Font Family (Monospace) — default SF Mono, Font Size — default 13, Line Height/Spacing — default Normal, Timestamp Format — default `[14:32:45]`
- Show line numbers in log viewer
- Enable word wrap in log viewer

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
- [ ] Default Shell picker — wire into `BuildRunner.start` (currently hardcoded to `/bin/bash`)
- [ ] Max Concurrent Builds field — wire into `BuildRunnerRegistry` (currently unlimited concurrent runners)
- [ ] Default Working Directory choice — wire into `BuildRunner.start`'s `currentDirectoryURL`
- [ ] Environment Variables editor (key=value pairs) — wire into `Process.environment`
- [ ] "Pass stdout/stderr to log file" shown as locked/always-on toggle (matches mockup's "(always on by default)" note)
- [ ] Custom build timeout field — wire into `BuildRunner` (auto-cancel after N minutes)
- [ ] Kill process tree on cancel toggle — wire into `BuildRunner.cancel()`

### 04 Logs & Console
- [ ] Log Retention (days) field — wire into a cleanup pass over `/build/logs/` (doesn't exist yet)
- [ ] Max Log File Size (MB) field — groundwork only, no size capping exists yet
- [ ] Compress old logs toggle — groundwork only
- [ ] Default Encoding picker — wire into `LogFileService` read/write
- [ ] "Open logs in external editor" toggle — wire into a new "open in editor" Quick Action
- [ ] Default Search mode (Match Case / Whole Word) — wire into `LogPane`'s search
- [ ] Font Family / Size / Line Height / Timestamp Format fields — wire into `LogPane`'s monospaced text rendering
- [ ] Show line numbers toggle — new feature in `LogPane`
- [ ] Word wrap toggle — new feature in `LogPane`

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
| 03 Build Execution | 0 / 7 | Open (pending Screen 3) |
| 04 Logs & Console | 0 / 9 | Open (pending Screen 4) |
| 05 Appearance | 0 / 1 | Open (pending Screen 5) |
| 06 Notifications | 0 / 2 | Open (pending Screen 6) |
| 07 Advanced | 0 / 3 | Open (pending Screen 7) |
| Polish | 0 / 1 | Open |
| **Total** | **0 / 50** | **Not started** |

## Screens Received

| Screen | Tab | Status |
| --- | --- | --- |
| 1 | General | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 2 | Repositories | ✅ Read and incorporated (image not yet saved to `assets/`) |
| 3 | Build Execution | ⏳ Waiting — fields below are still the early guesses from the concept mockup |
| 4 | Logs & Console | ⏳ Waiting — same |
| 5 | Appearance | ⏳ Waiting — same |
| 6 | Notifications | ⏳ Waiting — same |
| 7 | Advanced | ⏳ Waiting — same |

## Notes / Open Questions

1. Several toggles (Check for updates, toast/summary notifications, verbose logging, update channel, language) don't have a system to hook into yet — built as inert/stored-only settings first, wired up when the underlying feature exists. Flagged per item above so nothing is silently faked as "working."
2. **Duplicate field across tabs**: "Maximum recent repositories" appears on both the General and Repositories screens. Plan is to back both fields with the *same* stored value rather than two separate ones — worth confirming this is intentional (a shared setting shown in two places) rather than two different limits.
3. **Two similar-but-different restore toggles**: General's "Restore last opened repository on launch" (singular, the one active repo) vs. Repositories' "Automatically restore last opened repositories" (plural, the full previous set). Kept both since they read as genuinely different behaviors, but flagging in case that's not the intent.
4. GitHub access moved from an inline token field (early mockup) to a "Configure…" button opening a sub-sheet (Screen 2) — plan follows the newer screen.
5. Storage path: keeping `~/Library/Application Support/LXC-BRM/preferences.json` instead of the early mockup's `BuildManager/` folder name, for consistency with the app's existing stores.
6. This supersedes the placeholder `PreferencesView`/`Settings` scene built earlier today (2026-08-16); that code will be replaced, not kept alongside.
