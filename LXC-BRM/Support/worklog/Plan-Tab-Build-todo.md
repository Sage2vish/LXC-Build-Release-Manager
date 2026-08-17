# Plan — Build tab

> One of six tabs inside the [main panel's container](Plan-MainPanel-Container-todo.md).
> Siblings: [Logs](Plan-Tab-Logs-todo.md) · [History](Plan-Tab-History-todo.md) ·
> [Overview](Plan-Tab-Overview-todo.md) · [Docs](Plan-MarkdownExplorer-todo.md) ·
> [Settings](Plan-Tab-Settings-todo.md)

Script discovery, the scripts table, parameters, the resolved command, build execution, and the
live output terminal. This is the app's primary working surface.

## 00. Vertical split — scripts over output

The Build tab currently stacks the scripts table and Live Output inside one scrolling column, so
the output pane is a fixed block with dead space beneath it when there is little to show, and it
never reaches the status bar.

- [x] Split the tab vertically: the scripts table above, Live Output below.
- [x] Make the divider draggable, with 6pt breathing room either side.
- [x] Live Output fills down to the status bar.
- [x] Live Output occupies its full share whether empty or full. The table's old 130–300pt height window was left over from the scrolling-column layout and was leaving a dead band; removed.
- [x] Keep the scripts table scrollable within its own share.
- [ ] Keep the existing Maximize Log Pane behaviour working alongside the split.
- [ ] Preserve the split position while the repository stays selected.
- [x] Both panes hold a 180pt minimum.

## 1. Discovery and data model

- [x] Inspect the Build screen screenshot and functional requirements PDF one more time against the current codebase so the implementation matches the intended center workspace hierarchy.
- [x] Identify the exact data sources for the Build tab, including repository metadata, build script definitions, folder targets, parameter definitions, live output streams, and persisted history records.
- [x] Define the Build screen view model shape for the center workspace, including loading, empty, populated, running, stopped, error, and offline states.
- [x] Decide which fields belong to a build script row versus the active execution panel versus persisted history.
- [x] Map the repository context required to resolve standard-folder scripts versus in-repository scripts.
- [x] Confirm whether build scripts are loaded from local project files, a backing service, or a hybrid cache and document that boundary in code comments.
- [x] Define a canonical build script identifier that survives rename, refresh, and persistence operations.
- [x] Define a stable build run identifier and log session identifier for correlating execution, output, and history.
- [x] Create a shared type or model for build parameters so the UI can render text inputs, select menus, toggles, and file/path pickers consistently.
- [x] Add a folder/status resolution helper that can classify scripts as standard-folder, in-repository, missing, unavailable, or stale.
- [x] Add a lightweight error model for the Build tab that distinguishes validation errors, fetch errors, execution errors, and process termination states.
- [x] Confirm whether the Build workspace needs a command preview string, resolved path string, and environment summary for each script.
- [x] Document any assumptions about how build scripts are filtered for the selected repository.

## 2. Build scripts table

- [x] Implement the main scripts table/list in the center workspace with the same visual density, spacing, and row structure shown in the screenshot.
- [x] Render the script name, location/source, status badge, last run state, and any right-aligned row action affordances required by the spec.
- [x] Keep row selection and row activation separate so a click can select the script while a dedicated action launches the build.
- [x] Support sorting or stable ordering if the screenshot/spec implies a fixed script order.
- [x] Add visual treatment for the selected row, hovered row, disabled row, and unavailable row.
- [x] Add an empty-state panel for when no build scripts are available in the current repository.
- [x] Add a loading skeleton or placeholder state while scripts are being discovered.
- [x] Make the table horizontally resilient so long script names, folder paths, and parameter summaries do not break the layout.
- [x] Ensure the table can show the build script list without forcing the terminal or parameter panes off screen.
- [x] Wire row activation to load the script detail into the parameters/actions panel.
- [x] Preserve table scroll position when refreshing the script list if possible.

## 3. Standard-folder and in-repository status detection

- [x] Implement logic that determines whether a build script lives in a standard folder, inside the repository, or outside the active repository boundary.
- [x] Compute folder status from the repository root rather than relying on display text alone.
- [x] Show a clear badge or label for standard-folder scripts when they are treated differently by the build system.
- [x] Show a different badge or label for scripts discovered inside the repository tree.
- [x] Handle scripts whose underlying file or folder is missing, moved, or inaccessible.
- [x] Detect stale status when a build script record points to a path that no longer exists on disk.
- [x] Make the status logic reusable by both the table row and the detail pane.
- [x] Avoid false positives when folder names resemble standard locations but are not actually standard paths.
- [x] Add test coverage for path normalization, case sensitivity, relative path handling, and repository root changes.

## 4. Parameters

- [x] Render the selected build script’s parameters section in the center workspace with the same hierarchy as the screenshot.
- [x] Support parameter fields for required inputs, optional inputs, defaults, placeholders, and help text.
- [x] Handle text parameters, number parameters, boolean parameters, enum/select parameters, and path/file parameters.
- [x] Show required markers and inline validation states on a per-parameter basis.
- [x] Preserve user-entered parameter values when switching between scripts if that behavior is part of the spec.
- [x] Reset parameter values only when the selected script genuinely changes and the spec expects a reset.
- [x] Show a concise resolved-command or command-preview area if the build flow uses one.
- [x] Keep parameter controls aligned and touch-friendly enough for macOS pointer interaction and keyboard navigation.
- [x] Validate dependencies between parameters when one field affects the visibility or validity of another.
- [x] Keep parameter state serializable for persistence or restoration after refresh.

## 5. Actions

- [x] Implement the primary build action for the selected script.
- [x] Add secondary actions required by the Build screen spec, including stop, clear, open in new window, maximize, and save log.
- [x] Disable actions that are not valid for the current state, such as stop when nothing is running or save log when no output exists.
- [x] Show loading or in-progress feedback on the primary action while the build process is starting.
- [x] Confirm action grouping matches the screenshot and does not introduce extra controls beyond the Build tab scope.
- [x] Keep action labels and icons consistent with the native macOS look and the existing app style.
- [x] Add keyboard-accessible shortcuts or menu-equivalent entry points if the spec expects them.
- [x] Make sure destructive or state-resetting actions are clearly distinguishable from launch actions.

## 6. Add-build-script file chooser

- [x] Implement the add-build-script action if the Build tab includes one in the specification.
- [x] Use a native macOS file chooser or app-appropriate picker rather than a custom fake picker.
- [x] Limit the chooser to the expected file types or folders defined by the requirements.
- [x] Return the picked path into the build script discovery flow without duplicating path parsing.
- [x] Handle cancel, denied access, and unsupported selection states cleanly.
- [x] Reflect the newly added script in the scripts table without forcing a full app reload when possible.
- [x] Ensure the chooser respects repository scope and does not allow accidental selection outside the allowed boundary if that is a requirement.

## 7. Refresh

- [x] Add a refresh control for reloading build scripts, status, and any path-derived metadata.
- [x] Keep refresh scoped to the Build workspace so it does not disturb the already-complete shell areas.
- [x] Preserve current selection when the same script still exists after refresh.
- [x] Reconcile parameter state after refresh so stale values do not persist against a changed script definition.
- [x] Show a clear loading indicator while the refresh is running.
- [x] Surface refresh failures inline with enough detail to diagnose repository or path issues.
- [x] Avoid interrupting an active build unless the spec explicitly allows refresh to do so.

## 8. Scrolling and layout behavior

- [x] Verify the Build tab scroll behavior on the center workspace only.
- [x] Keep the scripts list, parameter section, and output terminal independently readable when content overflows.
- [x] Prevent the terminal from jumping unexpectedly when new output arrives unless auto-scroll is intentionally enabled.
- [x] Maintain stable row heights if the screenshot implies a compact table-like list.
- [x] Confirm the center workspace remains usable at smaller window sizes without clipping the critical controls.
- [x] Ensure the Build tab can support both a shorter and a longer output log without breaking the panel proportions.

## 9. Live output terminal

- [x] Build the live output terminal area for the active build process.
- [x] Render streaming output in chronological order with readable line wrapping and monospaced text.
- [x] Preserve ANSI/color formatting if the build system emits it and the design calls for it.
- [x] Add timestamps only if the requirements show them or if they materially help debugging.
- [x] Support auto-scroll while running and manual scrollback without fighting user position.
- [x] Distinguish stdout, stderr, warnings, and errors if the process stream provides those channels.
- [x] Show a waiting or idle terminal state before the first build starts.
- [x] Show a completion summary, termination reason, or final status when the process exits.
- [x] Ensure the terminal panel is copy-friendly and selection-friendly on macOS.

## 10. Stop, clear, open in new window, maximize, and save log

- [x] Wire the stop action to the actual running process and confirm it sends the correct termination signal or process-kill behavior.
- [x] Confirm stop transitions the UI into a terminal state that explains whether the process stopped cleanly or was interrupted.
- [x] Implement clear so it resets the visible output panel without destroying persisted run history unless the spec says otherwise.
- [x] Implement open in new window so the current build workspace or output can be detached into a separate macOS window.
- [x] Implement maximize so the center workspace can expand or focus the build area without breaking the app shell.
- [x] Implement save log so the current output can be exported to a file with a sensible default name and format.
- [x] Guard save-log behavior when there is no output yet.
- [x] Keep all of these actions in sync with current process state so the UI never offers impossible combinations.

## 11. Build execution and process handling

- [x] Create the process launch pipeline for a selected build script.
- [x] Merge selected parameters into the final command or invocation exactly once, in a single source of truth.
- [x] Capture process PID, start time, exit code, and termination reason.
- [x] Stream output incrementally into the terminal rather than waiting for process completion.
- [x] Handle multi-line output, partial line buffering, and process restarts correctly.
- [x] Prevent concurrent duplicate runs of the same script unless the product explicitly allows parallel builds.
- [x] Track running, stopping, stopped, succeeded, failed, and canceled states.
- [x] Recover cleanly from process launch failures, permission errors, and missing executable errors.
- [x] Ensure process cleanup runs when the window closes, the repository changes, or the user switches scripts if required.
- [x] Keep execution logic isolated from view rendering so it can be tested independently.

## 12. Persistence and history hooks

- [x] Persist the selected script, last-used parameter values, and any relevant build preferences if the product expects state restoration.
- [x] Hook build completion events into a history store or log history model.
- [x] Persist enough metadata to reconstruct prior runs, including script identity, parameters, timestamps, and result status.
- [x] Add restore-on-open behavior for the last active script if that is consistent with the rest of the app.
- [x] Keep history writes resilient so they do not block the UI or break the live build session.
- [x] Define whether save-log exports are separate from persistent run history.
- [x] Avoid writing duplicate history entries when a process is retried or refreshed.

## 13. Validation and error states

- [x] Validate selected scripts before launch and block execution with clear inline errors when required data is missing.
- [x] Validate parameter values before process start and again if they change during editing.
- [x] Show repository/path errors distinctly from build command errors.
- [x] Show a clear error state when the selected script cannot be found, opened, or parsed.
- [x] Handle invalid file chooser selections with a helpful message rather than silent failure.
- [x] Ensure the UI still makes sense when no repository is loaded, the repository is offline, or the script list fails to fetch.
- [x] Add a retry path for transient failures.
- [x] Keep error copy concise and actionable for the user.

## 14. Accessibility and native macOS behavior

- [x] Add proper accessibility labels, values, and hints for the scripts list, parameter fields, actions, and terminal.
- [x] Support full keyboard navigation through the Build tab controls.
- [x] Ensure focus order matches the visual order of the center workspace.
- [x] Provide visible focus rings and selection states that work with macOS accessibility settings.
- [x] Keep hit targets large enough for comfortable pointer use.
- [x] Respect system typography, color contrast, and reduced-motion preferences where the UI uses animation.
- [x] Make sure the file chooser, open-in-new-window, and maximize behaviors feel native on macOS.
- [x] Preserve standard copy, select-all, and text-selection behavior in the output terminal.

## 15. Visual fidelity

- [x] Match the screenshot’s center-workspace proportions, spacing, and visual emphasis without touching the completed shell areas.
- [x] Keep the Build tab visually aligned with the existing pink-and-blue brand identity and rounded card language.
- [x] Use the same surface, border, and shadow treatments already established elsewhere in the app.
- [x] Recreate the visual hierarchy between the scripts list, parameters, action row, and terminal panel.
- [x] Check that selected, active, and disabled states read clearly in both light and dark rendering contexts if supported.
- [x] Ensure the Build tab does not accidentally drift into a generic desktop admin style.
- [x] Verify typography, icon sizing, and vertical rhythm against the screenshot.
- [x] Make sure the center workspace still looks complete when empty or loading.

## 16. Testing

- [x] Add unit tests for script discovery and path classification helpers.
- [x] Add unit tests for parameter model mapping and validation rules.
- [x] Add unit tests for process lifecycle state transitions.
- [x] Add unit tests for stop, clear, save log, and history hook behaviors.
- [x] Add UI or integration tests for selecting a script, launching a build, streaming output, and stopping the process.
- [x] Add tests for refresh behavior while a script is selected.
- [x] Add tests for missing-folder, invalid-path, and empty-state handling.
- [x] Add accessibility checks for labels, focus order, and keyboard navigation.
- [x] Run the Build screen through Xcode previews or the closest equivalent visual check before marking the checklist complete.

## 17. Final acceptance

- [x] The Build tab center workspace matches the provided screenshot and requirements while leaving the shell, sidebars, and top header untouched.
- [x] A user can select a build script, review parameters, launch a build, watch live output, stop it, clear it, and save the log.
- [x] Standard-folder and in-repository scripts are correctly identified and displayed.
- [x] Refresh, scrolling, and window actions behave predictably on macOS.
- [x] Validation failures and runtime failures are clear and recoverable.
- [x] The UI is accessible, native-feeling, and visually consistent with the rest of MyHealthHub.
- [x] Tests cover the critical discovery, execution, and terminal workflows.
- [x] The checklist can be used as an execution tracker in GitHub, Xcode, and Codex without extra interpretation.
