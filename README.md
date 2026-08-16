# LXC Build Release Manager

This repository is organized around a BRM workspace model, with the native macOS app living in `LXC-BRM/`.

## Root Layout

- `LXC-BRM`

## Conventions

- The native app root is `LXC-BRM/`.
- The BRM workspace lives inside `LXC-BRM/BRM/`.
- Each BRM folder keeps its own `README.md`.
- Dated todo files use the `todo-YYYY-MM-DD.md` naming pattern, for example `todo-2026-08-16.md`.
- The dated todo file is the daily working note for that area and includes task, subtask, and tracking sections.
- The root `README.md` is the index that tracks what each area is for.

## Tracking Table

| Area | Purpose | Todo Path |
| --- | --- | --- |
| `LXC-BRM/BRM/LXC-BRM-shared` | Shared utilities and conventions | `LXC-BRM/BRM/LXC-BRM-shared/todo-2026-08-16.md` |
| `LXC-BRM/BRM/LXC-BRM-frameworks` | Framework-specific assets and adapters | `LXC-BRM/BRM/LXC-BRM-frameworks/todo-2026-08-16.md` |
| `LXC-BRM/BRM/LXC-BRM-build-release` | Build and release orchestration | `LXC-BRM/BRM/LXC-BRM-build-release/todo-2026-08-16.md` |
| `LXC-BRM/BRM/LXC-BRM-build-release/scripts` | Build script entry points | `LXC-BRM/BRM/LXC-BRM-build-release/scripts/build-ios.sh` |
| `LXC-BRM/BRM/LXC-BRM-build-release/logs` | Timestamped build logs | `LXC-BRM/BRM/LXC-BRM-build-release/logs/README.md` |
| `LXC-BRM/BRM/LXC-BRM-build-release/version` | Final versioned release output, including the `.dmg` | `LXC-BRM/BRM/LXC-BRM-build-release/version/README.md` |
| `LXC-BRM/BRM/LXC-BRM-worklog` | Daily progress and execution logs | `LXC-BRM/BRM/LXC-BRM-worklog/todo-2026-08-16.md` |
| `LXC-BRM/BRM/LXC-BRM-worklog/worklog-2026-08-16.md` | Written daily work summary | `LXC-BRM/BRM/LXC-BRM-worklog/worklog-2026-08-16.md` |
| `LXC-BRM/BRM/LXC-BRM-context` | Decisions, references, and operating notes | `LXC-BRM/BRM/LXC-BRM-context/todo-2026-08-16.md` |
| `LXC-BRM/BRM/LXC-BRM-context/rules-context.md` | Rules and operating constraints | `LXC-BRM/BRM/LXC-BRM-context/rules-context.md` |
| `LXC-BRM/BRM/LXC-BRM-context/architecture.md` | Current architecture model | `LXC-BRM/BRM/LXC-BRM-context/architecture.md` |
| `LXC-BRM/BRM/LXC-BRM-context/decisions` | Dated decision logs | `LXC-BRM/BRM/LXC-BRM-context/decisions/decision-2026-08-16.md` |

## Desktop Utility

The macOS SwiftUI app in `LXC-BRM/` is the desktop shell for navigating the BRM areas, viewing status, and tracking dated notes.

## Current Release Map

- Build scripts live in `LXC-BRM/BRM/LXC-BRM-build-release/scripts/`
- Build logs are written to `LXC-BRM/BRM/LXC-BRM-build-release/logs/`
- Final release packages go to `LXC-BRM/BRM/LXC-BRM-build-release/version/`
- Project tracking lives in `LXC-BRM/BRM/LXC-BRM-build-release/projects.json`
- Daily todo notes use `LXC-BRM/BRM/LXC-BRM-*/todo-2026-08-16.md`
- Worklog summaries use `LXC-BRM/BRM/LXC-BRM-worklog/worklog-2026-08-16.md`
- Context rules live in `LXC-BRM/BRM/LXC-BRM-context/rules-context.md`
- Context architecture lives in `LXC-BRM/BRM/LXC-BRM-context/architecture.md`
- Decisions live in `LXC-BRM/BRM/LXC-BRM-context/decisions/`
