# Current context

Where the project actually stands right now — the one page to read before doing anything, and the
first thing to correct when it stops being true.

**Last reviewed:** 2026-08-18

## What this is

LXC Build Release Manager is a native macOS app that turns a repository's own shell scripts into a
visible, runnable, recorded workspace. It discovers `build/scripts/*.sh`, runs them locally with
the repository root as the working directory, streams timestamped output, and keeps the log and the
result. It is not a CI platform and does not try to be: the argument for it is inspectability.

## Shape of the repository

| Path | Holds |
| --- | --- |
| `App/`, `Tests/` | The Swift sources and the unit-test target |
| `LXC-Build-Release-Manager.xcodeproj` / `.xcworkspace` | The project, at the repository root, with a shared scheme |
| `build/scripts/` | This project's own build, test and release commands — the app can run them |
| `Support/context/` | Rules, architecture, requirements, decisions, this file |
| `Support/worklog/` | The plan index and one plan per area |
| `Support/research/` | Open questions, no tasks, nothing counted |
| `Support/build-release/` | Release script, staging contract, user guide, tooling |

## Current state

| Signal | Value |
| --- | --- |
| Release line | `0.1.2`; nothing published to GitHub Releases yet |
| Platform | macOS 15+, Swift 6, SwiftUI + AppKit, no third-party packages |
| Build | `BUILD SUCCEEDED`, no project warnings |
| Tests | **80 tests, 0 failures** (2026-08-18) |
| Delivery | Generated from the plans; see [`../worklog/BRM-Plan-todo.md`](../worklog/BRM-Plan-todo.md) |
| CI | One workflow: build, test, and a stale-index check |

## What is true about the work

- Every surface has exactly one owning plan, and the master index links them all. Counts in the
  index are generated from the checkboxes, never typed.
- The app is largely built and largely **not click-tested**. Most `[x]` marks are at compile or
  unit-test level; what has actually been driven in the GUI is listed honestly in
  [`../worklog/Plan-QualityVerification-todo.md`](../worklog/Plan-QualityVerification-todo.md).
  That gap, not the feature list, is the real state of the project.
- Preferences has 73 fields and every one has a consumer, but the plan's per-field markers still
  predate the audit that proved it, so they read more pessimistic than the code.
- The workspace was flattened and the `LXC-BRM` codename retired on 2026-08-18. Existing installs
  migrate their Application Support folder on first launch.

## The boundaries that decide arguments

1. A GitHub repository can be **scanned** but never **built** — running a shell needs a real
   working directory.
2. Repository build logs belong to the repository (`build/logs/`), not to app data.
3. App state lives in `~/Library/Application Support/LXC-Build-Release-Manager/`, and those file
   names are a contract: changing one needs a migration.
4. No third-party packages. Apple frameworks only.
5. A compile closes nothing that a person can see.

## Where to go next

| To… | Read |
| --- | --- |
| Pick up work | [`../worklog/BRM-Plan-todo.md`](../worklog/BRM-Plan-todo.md) |
| Know what is proven | [`../worklog/Plan-QualityVerification-todo.md`](../worklog/Plan-QualityVerification-todo.md) |
| Know why it is shaped this way | [`rules.md`](rules.md), [`architecture.md`](architecture.md), [`decisions/`](decisions/) |
| See what is being considered | [`../research/README.md`](../research/README.md) |
