# Architecture

## UI Architecture

- Native SwiftUI app.
- Main shell uses a `NavigationSplitView`: repository sidebar, repository detail pane, and an optional build inspector.
- Reusable sidebar components (`RepositoryRow`, `RecentRepositoryRow`, `AddRepositorySheet`, `StatusBar`) live in dedicated Swift files instead of being duplicated in the app shell.
- The detail pane owns Build, Logs, History, Overview, and Settings tabs for the selected repository.
- UI copy reflects actual repository state, build output, and saved preferences.

## Workspace Architecture

- `LXC-BRM/` is the Xcode-openable native app container.
- `Support/` contains the workspace folders and documentation.
- `shared/` holds shared helpers and conventions.
- `frameworks/` holds framework-specific assets only.
- `build-release/` holds build scripts, logs, release mapping, and version output.
- `build-release/version/` is the final `.dmg` staging folder.
- Local release builds can skip code signing while staging the DMG, because the release script is only producing a distributable local artifact in this repo.
- `worklog/` records daily activity and progress.
- `context/` records rules, architecture, and decisions.

## Documentation Architecture

- Root `README.md` is the top-level index.
- Each support area has its own `README.md`.
- Active todo tracking lives only in `worklog/todo-2026-08-16.md`.
- Other support areas keep README files and reference notes, not their own todo files.
- Decision records go under `decisions/`.
- Tracking sections must stay short and actionable.

## Decision Precedence

- PDF requirements define the requested scope.
- Recorded decisions define the current implementation path.
- If they conflict, the decision log wins and the mismatch stays documented.
