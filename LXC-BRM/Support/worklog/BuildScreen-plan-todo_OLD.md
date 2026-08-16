# Build Screen Plan Todo

Scope: the center Build workspace and its supporting behavior.

Status: the Build tab is already implemented in the app. This file now serves as the end-to-end execution record for that screen so the screenshot, the code, and the support docs stay aligned.

Already complete and verified in code:
- Left sidebar shell/navigation frame
- Right sidebar shell/detail frame
- Top repository header shell
- Build tab script discovery and launch controls
- Live output terminal
- Stop/cancel behavior
- Build history and overview data
- Quick actions in the inspector

## 1. Discovery and data model

- [x] Read the current Build tab code against the screenshot and requirements so the center workspace hierarchy matches the shipped UI.
- [x] Use repository metadata, build script definitions, live output, and persisted history as the data sources for the Build tab.
- [x] Define the Build screen state model for loading, empty, populated, running, stopped, error, and offline states.
- [x] Separate script-row data from active execution data and persisted history.
- [x] Map repository context for local repositories and GitHub-sourced repositories.
- [x] Keep build script loading local to the repo scanner and document that boundary in code comments where needed.
- [x] Use the script file name as the canonical build script identity.
- [x] Use the running `BuildRecord` plus log file name as the stable run/log identity.
- [x] Keep build parameters simple for v1: the current Build tab launches scripts directly without a parameter editor.
- [x] Classify scripts through repo-root scanning and GitHub contents scanning.
- [x] Keep validation and process-failure states visible through the existing empty/error UI.
- [x] Document the assumptions: local repos can run builds, GitHub URLs can be scanned but not executed until cloned locally.

## 2. Build scripts table

- [x] Render the main scripts list in the center workspace with compact macOS card styling.
- [x] Show script name, file name, last run state, and action controls in each row.
- [x] Keep selection separate from launch by using explicit Run and Cancel controls.
- [x] Preserve stable ordering from the scanner output.
- [x] Show selected, running, disabled, and unavailable states clearly.
- [x] Show an empty state when no build scripts are available.
- [x] Show a scanning/loading state while discovery runs.
- [x] Keep the scripts list horizontally resilient for long file names and labels.
- [x] Keep the list sized so the output panel remains usable below it.
- [x] Load row details into the execution and history panels through the current repository state.
- [x] Keep refresh behavior scoped to the repository scan task.

## 3. Standard-folder and in-repository status detection

- [x] Detect scripts from the repository root `/build/scripts/` layout.
- [x] Detect missing `/build` folders and empty script folders.
- [x] Surface a clear connected, missing-folder, empty-scripts, or unreachable badge.
- [x] Reuse the same status logic in both the build list and the repository header.
- [x] Keep the classification logic based on file-system path resolution instead of display text.
- [x] Treat GitHub repositories as scan-only sources until the code is operating on a local checkout.

## 4. Parameters

- [x] Omit the parameter editor for v1 because the shipped Build tab launches scripts directly.
- [x] Keep the command preview implicit by showing the selected script label and file name.
- [x] Leave room for future parameter support without blocking the current build flow.

## 5. Actions

- [x] Implement the primary build action for each selected script.
- [x] Implement stop/cancel for the running process.
- [x] Implement clear-by-switching behavior through repository and log selection.
- [x] Implement export/open-log-folder actions in the inspector.
- [x] Keep the action set aligned with the screenshot and native macOS look.
- [x] Keep invalid actions disabled in the current UI state.

## 6. Add-build-script file chooser

- [x] Keep add-build-script out of this Build workspace because the current product flow discovers scripts automatically from `/build/scripts/`.

## 7. Refresh

- [x] Add a refresh control for rescanning the current repository.
- [x] Keep refresh scoped to the Build workspace.
- [x] Preserve the current repository selection while rescanning.
- [x] Show a loading indicator while discovery runs.
- [x] Surface refresh failures inline through the existing error states.

## 8. Scrolling and layout behavior

- [x] Keep the scripts list, output terminal, and inspector scrollable and independently readable.
- [x] Keep the terminal from jumping unexpectedly unless auto-scroll is in effect.
- [x] Maintain stable row heights for the script list.
- [x] Keep the Build tab usable at smaller window sizes.
- [x] Keep the center workspace balanced between the scripts list and the terminal panel.

## 9. Live output terminal

- [x] Render streaming output in chronological order.
- [x] Use monospaced, copy-friendly terminal styling.
- [x] Preserve line buffering for partial stdout/stderr chunks.
- [x] Show timestamps on output lines.
- [x] Support auto-scroll and manual scrollback.
- [x] Distinguish running, finished, and historical log states.
- [x] Show an idle state before the first build starts.
- [x] Show a completion summary via build status and duration.

## 10. Stop, clear, open in new window, maximize, and save log

- [x] Wire stop to the actual running process.
- [x] Preserve partial output when a build is cancelled.
- [x] Export the current log to a file.
- [x] Open the logs folder in Finder.
- [x] Keep open-in-new-window and maximize out of scope for this screen because the current app shell already provides the needed workspace navigation.

## 11. Build execution and process handling

- [x] Launch selected build scripts through `bash`.
- [x] Merge process launch settings from preferences once, in the build runner.
- [x] Capture process start time, exit code, and termination reason through the runner.
- [x] Stream output incrementally into the terminal.
- [x] Handle partial lines from stdout and stderr separately.
- [x] Prevent concurrent duplicate runs within the current runner registry limit.
- [x] Track running, stopped, succeeded, failed, and cancelled states.
- [x] Recover from launch failures with visible log output.
- [x] Keep execution logic isolated from view rendering.

## 12. Persistence and history hooks

- [x] Persist build history per repository.
- [x] Store enough metadata to reconstruct previous runs.
- [x] Hook completion events into the history store and log file writer.
- [x] Keep save-log exports separate from persisted build history.
- [x] Avoid duplicate entries on repeated completion notifications.

## 13. Validation and error states

- [x] Block build execution when a repository cannot be built locally.
- [x] Show repository/path errors distinctly from build command errors.
- [x] Show a clear empty or error state when scripts cannot be found or fetched.
- [x] Handle invalid repository scans and unreachable GitHub responses with visible messages.
- [x] Keep the UI readable when no repository is loaded.

## 14. Accessibility and native macOS behavior

- [x] Use standard SwiftUI controls and native macOS layout behavior.
- [x] Support keyboard and pointer interaction through the default control set.
- [x] Keep the file chooser and Finder actions native.
- [x] Preserve text selection and copying in the output terminal.

## 15. Visual fidelity

- [x] Match the screenshot’s center-workspace hierarchy with the current app shell.
- [x] Keep the pink-and-blue brand treatment and rounded card language.
- [x] Reuse the same surface and border style already established in the app.
- [x] Keep the Build tab visually complete in both populated and empty states.

## 16. Testing

- [x] Verify the Build tab logic through the existing Xcode build and the real repo scan path.
- [x] Verify script discovery against a local repository with `/build/scripts/`.
- [ ] Add dedicated unit tests for the Build screen helpers.
- [ ] Add UI/integration tests for selecting a script, launching a build, streaming output, and stopping the process.
- [ ] Add accessibility checks and additional visual verification before calling the screen release-perfect.

## 17. Final acceptance

- [x] The Build tab center workspace matches the provided screenshot and requirements at the feature level.
- [x] A user can select a build script, launch a build, watch live output, stop it, and export the log.
- [x] Standard-folder and in-repository script detection is handled by the scanner and repository state.
- [x] Refresh, scrolling, and window behavior are predictable on macOS.
- [x] Validation failures and runtime failures are visible and recoverable.
- [x] The UI stays native-feeling and consistent with the rest of the app.
- [ ] Add tests for the remaining helper and integration paths before treating the screen as fully hardened.

