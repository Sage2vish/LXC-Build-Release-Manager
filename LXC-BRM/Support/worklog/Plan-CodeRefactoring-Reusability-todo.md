# Code Refactoring and Reusability

![Refactor](https://img.shields.io/badge/refactor-architecture-3155E8?style=for-the-badge&labelColor=0B1020)
![Swift](https://img.shields.io/badge/Swift-6.0-FF7357?style=for-the-badge&labelColor=0B1020)
![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-28B487?style=for-the-badge&labelColor=0B1020)
![Scope](https://img.shields.io/badge/scope-reuse%20%7C%20testability%20%7C%20clarity-8E9EFF?style=for-the-badge&labelColor=0B1020)

> A behavior-preserving refactor plan for making LXC-BRM easier to extend, test, and reuse without turning the native macOS app into an abstract framework exercise.

## Status

| Signal | Current state |
| --- | --- |
| Assessment | Complete |
| Refactor implementation | In progress — sections 03 and 05 landed |
| Baseline Debug build | Passing on the current working tree |
| Third-party packages | None; keep the refactor package-free |
| Primary risk | Extracting code while preserving build execution, persistence, and SwiftUI state behavior |

## Refactor Promise

This pass is not a visual redesign and not a rewrite of the product. It is an incremental architecture pass with four outcomes:

1. Views describe UI and user intent instead of owning filesystem, process, and persistence details.
2. Services have one responsibility and explicit seams for tests and future reuse.
3. Shared behavior lives in named, discoverable modules instead of private helpers or singleton lookups.
4. Existing users keep their repositories, preferences, history, logs, release commands, and native macOS workflow.

## Assessment Snapshot

The assessment was made against the current implementation, Xcode project, tests, and Support rules.

| Finding | Evidence | Refactor decision |
| --- | --- | --- |
| The app shell and repository workspace are concentrated in one file. | `App/ContentView.swift` is 1,939 lines and contains the shell, sidebar, log presentation, window controller, script table row, repository detail view, five tabs, inspector cards, file actions, and build actions. | Extract by feature boundary, starting with log presentation and repository detail tabs. Keep `ContentView` as a thin composition shell. |
| The log surface is duplicated across live output and saved-log paths. | `LogPane`, `DisplayLine`, ANSI parsing, filter state, window presentation, export closures, and log loading all live in `ContentView.swift`. | Create a reusable Logs feature with a pure presentation model and injected actions. |
| The repository detail view has a wide dependency surface. | `RepositoryDetailView` observes repository, history, workspace state, preferences, runner registry, and runner, plus owns many unrelated `@State` values. | Introduce a feature-facing workspace model/dependency container and split Build, Logs, History, Overview, Settings, and Inspector views. |
| Runtime dependencies are globally constructed. | `RepositoryStore`, `BuildHistoryStore`, `BuildWorkspaceStateStore`, `PreferencesStore`, `BuildRunnerRegistry`, and `BuildNotificationService` expose `static shared` access. | Keep production singletons only at the composition root; inject protocols or concrete dependencies into feature views and services. |
| Persistence code repeats path, encoder, directory, and silent-error behavior. | Repository, history, preferences, and workspace stores each create Application Support paths and use `try?` for load/save. | Centralize paths and JSON persistence while preserving each existing file name and JSON shape. Make failures observable. |
| Large services combine policy, platform I/O, and formatting. | `BuildRunner.swift`, `BuildScriptScanner.swift`, and `LogFileService.swift` each contain multiple separable responsibilities. | Split process execution, script discovery, parsing, log formatting, storage, pruning, and AppKit presentation behind focused seams. |
| Domain logic is mixed into model files and views. | `BuildScript.swift` contains command validation/building; `ContentView.swift` contains status formatting, duration formatting, parameter bindings, and log parsing. | Move pure domain rules and display formatting into reusable, testable files. |
| Preferences contain many string-backed choices and duplicate save-log flags. | `Models/Preferences.swift` has a broad 136-line value model; `PreferencesView.swift` is 469 lines with seven tabs and inline row helpers. | Audit the preference contract first, then introduce typed values/migrations and split tab views without silently changing behavior. |
| Test coverage is valuable but concentrated. | `Tests/BuildWorkspaceTests.swift` covers scanning, command building, persistence fixtures, folder import, and runner behavior, but platform side effects are not injected. | Preserve the existing tests and add focused suites around extracted seams, failure reporting, and compatibility. |
| The Xcode project uses explicit file references. | `LXC-BRM.xcodeproj/project.pbxproj` lists source files and resources manually. | Treat target membership and project-file updates as a required step for every extracted Swift file. |

## Current Dependency Shape

```text
LXC_BRMApp
  -> ContentView
      -> RepositoryStore.shared
      -> BuildHistoryStore.shared
      -> BuildWorkspaceStateStore.shared
      -> PreferencesStore.shared
      -> BuildRunnerRegistry.shared
      -> AppKit side effects and LogFileService static calls

RepositoryDetailView
  -> BuildScriptScanner / DeepScriptSearch
  -> BuildRunner / BuildRunnerRegistry
  -> BuildHistoryStore / BuildWorkspaceStateStore
  -> PreferencesStore
  -> LogFileService / NSWorkspace / NSPasteboard / NSOpenPanel

Persistence stores
  -> FileManager.default
  -> Application Support JSON files
```

The target direction is:

```text
LXC_BRMApp
  -> AppDependencies.production()
      -> AppShellView
          -> RepositoryFeature
          -> BuildFeature
          -> LogsFeature
          -> HistoryFeature
          -> PreferencesFeature

Features
  -> protocols or focused concrete services
  -> injected platform gateways
  -> pure domain models and use-case results
```

The target is a direction, not permission to introduce layers without a consumer. A new abstraction must remove duplication, improve a test seam, or clarify ownership.

## Work Plan

### 01. Lock the Refactor Baseline

- [x] Inventory the current App, Models, Services, Views, Tests, Xcode project, and Support ownership rules.
- [x] Identify the main extraction boundary: `ContentView.swift` and its embedded feature views.
- [x] Identify the main reuse boundary: persistence, filesystem, process, notification, and AppKit side effects.
- [x] Confirm the package-free constraint and native SwiftUI/AppKit stack.
- [x] Run the baseline Debug build before changing architecture: `xcodebuild -project LXC-BRM/LXC-BRM.xcodeproj -scheme LXC-BRM -configuration Debug CODE_SIGNING_ALLOWED=NO build`.
- [x] Run the baseline test target and record the result before the first code refactor.
- [x] Record a short dated worklog entry with the baseline build/test evidence.

### 02. Establish Safe Seams Before Moving Code

- [ ] Define the production composition root and name the dependency container, without changing runtime behavior.
- [ ] Decide which boundaries need protocols and which can use injected concrete types; do not protocolize every model.
- [ ] Inject `FileManager`, `URLSession` or a GitHub client seam, process creation, notification delivery, pasteboard, workspace opening, save panels, and clock/date behavior where tests need control.
- [ ] Keep `@MainActor` ownership explicit for observable UI stores and build lifecycle state.
- [ ] Add characterization tests for current persistence, scanner, command, logging, cancellation, and runner behavior before moving implementation.
- [ ] Define migration rules for existing JSON files before changing any `Codable` model or preference representation.

### 03. Centralize Persistence and Application Paths

- [x] Create one application-support path provider for `projects.json`, `selected-repository.json`, `build-history.json`, `preferences.json`, and `build-workspace-state.json`.
- [x] Create a small reusable JSON file boundary for date encoding, sorted output, atomic writes, directory creation, and injected URLs.
- [x] Move each store to the shared boundary while preserving its public behavior and on-disk file names.
- [x] Replace silent persistence failures that matter with typed results, diagnostics, or user-visible recovery paths.
- [x] Keep log file paths separate from Application Support because repository-local `build/logs/` is part of the product contract.
- [x] Add tests for missing files, malformed JSON, write failures, legacy records, and recovery without touching the real user directory.

### 04. Extract the App Shell and Repository Features

- [x] Reduce `ContentView.swift` to app-shell composition, sidebar selection, settings presentation, status bar placement, and dependency wiring.
- [ ] Extract the repository sidebar composition and keep `RepositoryRow`, `RecentRepositoryRow`, and status-bar components reusable with injected stores.
- [ ] Extract `RepositoryDetailView` into a feature coordinator/view model with a small, explicit dependency surface.
- [ ] Extract the repository header, connection status, source actions, and repository settings into focused views.
- [ ] Extract the Build tab into script discovery, script table, parameter controls, command preview, and build-output components.
- [ ] Extract the Inspector into selected-script detail, build status, build history, and quick-action components.
- [ ] Extract History and Overview into reusable repository-scoped views driven by `BuildRecord` and `RepositoryStats`.
- [ ] Preserve repository switching behavior by keeping repository identity as the state-reset boundary.

### 05. Make Logs a Reusable Feature

- [x] Move `DisplayLine`, `TerminalLineColor`, `LogFilter`, stream parsing, ANSI cleanup, and display-line conversion out of `ContentView.swift`.
- [x] Make log filtering, search matching, line numbering, color selection, and duration/status formatting pure and unit-testable.
- [x] Extract `LogPane` into a dedicated view that accepts a log model and action closures rather than reaching into repository/build services.
- [x] Extract `LogWindowController` into a small AppKit presentation gateway with a testable call site.
- [ ] Consolidate live output, saved log, export, clear, stop, and separate-window behavior so the live and history tabs reuse one path.
- [ ] Verify auto-scroll, search navigation, filter selection, ANSI colors, line numbers, word wrap, accessibility labels, and reduced-motion behavior are unchanged.

### 06. Split Domain and Service Responsibilities

- [x] Split `BuildScript.swift` into focused files for script domain data, parameter definitions, command construction, validation, and path identity/location rules.
- [ ] Split `BuildScriptScanner` into local filesystem discovery, GitHub Contents API discovery, script metadata parsing, and result mapping.
- [ ] Give local scanning and GitHub scanning a shared result contract while keeping remote scripts non-runnable.
- [ ] Split `BuildRunner` into build lifecycle coordination, process transport/output buffering, timeout and process-tree control, and completion recording where the seams are proven useful.
- [ ] Keep `BuildRunnerRegistry` responsible only for per-repository runner ownership and concurrency lookup.
- [ ] Split `LogFileService` into log path resolution, formatting, storage/pruning, reading, and AppKit export presentation.
- [x] Move shared status symbols, colors, duration formatting, relative dates, and display labels into named presentation utilities instead of private view helpers.
- [x] Keep `BuildScriptFolderImport` and `DeepScriptSearch` reusable as pure decision/walk services with injected filesystem access where needed.

### 07. Refactor Preferences Without Breaking User Data

- [ ] Audit every `Preferences` field against its actual consumer and classify it as active, UI-only, planned, duplicated, or obsolete.
- [ ] Resolve the duplicated `saveLogsAutomatically` and `automaticallySaveLogs` contract with an explicit compatibility strategy.
- [ ] Replace stable string-backed choices with typed enums only where decoding migration is defined and tested.
- [ ] Split `PreferencesView.swift` into tab views and reusable preference-row components while keeping one draft/save/cancel flow.
- [ ] Move path and maintenance actions behind injected system gateways rather than calling `NSWorkspace` and `#filePath` from the view.
- [ ] Add migration tests for old preference files and tests proving save/cancel/default behavior.

### 08. Improve Testability and Verification

- [ ] Split `BuildWorkspaceTests.swift` by domain/service responsibility once the production seams exist.
- [ ] Add persistence tests for every store using temporary URLs and deterministic encoders/clocks.
- [ ] Add scanner tests for local and GitHub response mapping, path boundaries, stale scripts, duplicates, and cancellation.
- [ ] Add command-builder tests for all parameter kinds, conditional visibility, validation, and shell escaping.
- [ ] Add log tests for stream markers, ANSI cleanup, filters, searches, truncation, retention, and export content.
- [ ] Add runner tests for start, success, failure, cancellation, timeout, partial output, concurrency limits, and history recording through fakes where possible.
- [ ] Keep GUI verification separate: compile/test success does not close macOS click-through, accessibility, performance, or packaging work.

### 09. Project, Documentation, and Cleanup

- [x] Add every extracted Swift file to the Xcode project and the correct target exactly once.
- [ ] Keep folder ownership clear: Models for domain values, Services for behavior and I/O, Views for presentation, and composition files for wiring.
- [ ] Remove dead code and obsolete private helpers only after references and tests are confirmed.
- [ ] Update `Support/context/architecture.md` with the final dependency and feature boundaries.
- [ ] Update the runtime SVG architecture map if the refactor changes the documented component boundaries.
- [ ] Add the implementation story and verification evidence to the dated worklog.
- [ ] Review the final diff for unrelated changes before committing.

## Non-Goals

- Do not introduce a third-party dependency solely to create an abstraction.
- Do not rewrite the app in TCA, MVVM, Redux, or another architecture by label alone.
- Do not change the native macOS SwiftUI/AppKit product direction.
- Do not change repository, history, preferences, or log file formats without migration coverage.
- Do not combine this refactor with a visual redesign, feature expansion, or GitHub Actions implementation.
- Do not mark a task complete because a file was moved; the new boundary must compile, preserve behavior, and have appropriate verification.

## Acceptance Gate

The refactor is complete only when all of the following are true:

1. `ContentView.swift` is an app-shell composition file, not the home for feature implementation and platform side effects.
2. Views receive the dependencies they use and no feature view directly reaches for global service singletons.
3. Persistence, scanning, command building, logging, and build execution have clear ownership and test seams.
4. Existing JSON data, local logs, build scripts, GitHub discovery, cancellation, and release commands continue to work.
5. Debug build, unit tests, GUI smoke checks, and release packaging verification are recorded.
6. Context architecture, worklog status, and Xcode target membership agree with the final source tree.

## Completion Record

| Check | Result |
| --- | --- |
| Code structure assessment | Complete |
| Baseline Debug build | Complete |
| Baseline tests | Complete: 14 passed |
| Dependency boundaries | Pending |
| Feature extraction | ContentView is now a 324-line shell; per-tab split pending |
| Persistence and platform seams | Persistence done; platform gateways pending |
| Test expansion | 21 passing (was 14) |
| Final build, test, GUI, and release verification | Pending |

_This is the refactoring execution ledger. Only mark an implementation line `[x]` after the complete boundary, behavior, and verification condition is satisfied._
