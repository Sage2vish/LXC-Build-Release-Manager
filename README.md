# LXC Build Release Manager

This repository is organized around a BRM workspace model, with the native macOS app living in `lxc-brm-macos/`.

## Root Layout

- `lxc-brm-macos`
- `LXC-BRM-shared`
- `LXC-BRM-frameworks`
- `LXC-BRM-build-release`
- `LXC-BRM-worklog`
- `LXC-BRM-context`

## Conventions

- Each BRM folder keeps its own `README.md`.
- Dated todo files use the `todo-YYYY-MM-DD.md` naming pattern, for example `todo-2026-08-16.md`.
- The dated todo file is the daily working note for that area and includes task, subtask, and tracking sections.
- The root `README.md` is the index that tracks what each area is for.

## Tracking Table

| Area | Purpose | Todo Path |
| --- | --- | --- |
| `LXC-BRM-shared` | Shared utilities and conventions | `LXC-BRM-shared/todo-2026-08-16.md` |
| `LXC-BRM-frameworks` | Framework-specific assets and adapters | `LXC-BRM-frameworks/todo-2026-08-16.md` |
| `LXC-BRM-build-release` | Build and release orchestration | `LXC-BRM-build-release/todo-2026-08-16.md` |
| `LXC-BRM-build-release/scripts` | Build script entry points | `LXC-BRM-build-release/scripts/build-ios.sh` |
| `LXC-BRM-build-release/logs` | Timestamped build logs | `LXC-BRM-build-release/logs/README.md` |
| `LXC-BRM-build-release/version` | Final versioned release output, including the `.dmg` | `LXC-BRM-build-release/version/README.md` |
| `LXC-BRM-worklog` | Daily progress and execution logs | `LXC-BRM-worklog/todo-2026-08-16.md` |
| `LXC-BRM-context` | Decisions, references, and operating notes | `LXC-BRM-context/todo-2026-08-16.md` |
| `LXC-BRM-context/rules-context.md` | Rules and operating constraints | `LXC-BRM-context/rules-context.md` |
| `LXC-BRM-context/architecture.md` | Current architecture model | `LXC-BRM-context/architecture.md` |
| `LXC-BRM-context/decisions` | Dated decision logs | `LXC-BRM-context/decisions/decision-2026-08-16.md` |

## Desktop Utility

The macOS SwiftUI app in `lxc-brm-macos/` is the desktop shell for navigating the BRM areas, viewing status, and tracking dated notes.

## Current Release Map

- Build scripts live in `lxc-brm-macos/BRM/LXC-BRM-build-release/scripts/`
- Build logs are written to `lxc-brm-macos/BRM/LXC-BRM-build-release/logs/`
- Final release packages go to `lxc-brm-macos/BRM/LXC-BRM-build-release/version/`
- Project tracking lives in `lxc-brm-macos/BRM/LXC-BRM-build-release/projects.json`
- Daily todo notes use `lxc-brm-macos/BRM/LXC-BRM-*/todo-2026-08-16.md`
- Context rules live in `lxc-brm-macos/BRM/LXC-BRM-context/rules-context.md`
- Context architecture lives in `lxc-brm-macos/BRM/LXC-BRM-context/architecture.md`
- Decisions live in `lxc-brm-macos/BRM/LXC-BRM-context/decisions/`
