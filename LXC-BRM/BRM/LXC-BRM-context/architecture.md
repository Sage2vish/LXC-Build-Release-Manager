# Architecture

## UI Architecture

- Native SwiftUI app.
- Main shell uses a `NavigationSplitView`: repository sidebar, repository detail pane, and an optional build inspector.
- Reusable sidebar components (`RepositoryRow`, `RecentRepositoryRow`, `AddRepositorySheet`, `StatusBar`) live in dedicated Swift files instead of being duplicated in the app shell.
- The detail pane owns Build, Logs, History, Overview, and Settings tabs for the selected repository.
- UI copy reflects actual repository state, build output, and saved preferences.

## Workspace Architecture

- `LXC-BRM/` is the Xcode-openable native app container.
- `BRM/` contains the workspace folders and documentation.
- `LXC-BRM-shared/` holds shared helpers and conventions.
- `LXC-BRM-frameworks/` holds framework-specific assets only.
- `LXC-BRM-build-release/` holds build scripts, logs, release mapping, and version output.
- `LXC-BRM-build-release/version/` is the final `.dmg` staging folder.
- Local release builds can skip code signing while staging the DMG, because the release script is only producing a distributable local artifact in this repo.
- `LXC-BRM-worklog/` records daily activity and progress.
- `LXC-BRM-context/` records rules, architecture, and decisions.

## Documentation Architecture

- Root `README.md` is the top-level index.
- Each BRM area has its own `README.md`.
- Active todo tracking lives only in `LXC-BRM-worklog/todo-2026-08-16.md`.
- Other BRM areas keep README files and reference notes, not their own todo files.
- Decision records go under `decisions/`.
- Tracking sections must stay short and actionable.

## Decision Precedence

- PDF requirements define the requested scope.
- Recorded decisions define the current implementation path.
- If they conflict, the decision log wins and the mismatch stays documented.
