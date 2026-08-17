# LXC-BRM Support Handbook

<p align="center">
  <strong>The project map behind the Build Manager.</strong><br>
  Build and release operations, AI-readable context, framework notes, shared ideas, and execution history live here.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/support-build%20%7C%20context%20%7C%20frameworks-2563EB" alt="Support areas">
  <img src="https://img.shields.io/badge/release-0.1.2-7C3AED" alt="Release 0.1.2">
  <img src="https://img.shields.io/badge/status-native%20macOS-111827?logo=apple&logoColor=white" alt="Native macOS">
  <img src="https://img.shields.io/badge/dependencies-none-059669" alt="No third-party dependencies">
</p>

> This folder is the operating system for the project itself. The app executes the build work; Support explains the contract, records the decisions, maps the release, and gives humans and AI tools enough context to work safely.

## The project story

LXC-BRM is a native macOS build and release manager for repositories that expose their build workflow as scripts. The product is organized around one simple loop:

1. Discover what a repository can build.
2. Run a local build with visible, timestamped output.
3. Preserve the result as a log, history record, and release signal.
4. Keep the knowledge needed for the next change close to the code.

The Support tree makes that loop understandable and repeatable. It is intentionally separated into five roles:

| Role | What it answers | Folder |
| --- | --- | --- |
| Build and release | How do we build, package, stage, and describe an artifact? | [`build-release/`](build-release/README.md) |
| Context | What are we building, why, which decisions are authoritative, and how do the system boundaries connect? | [`context/`](context/README.md) |
| Frameworks | Which system frameworks, adapters, and package ideas are available? | [`frameworks/`](frameworks/README.md) |
| Shared | Which conventions and reusable support ideas should stay consistent? | [`shared/`](shared/README.md) |
| Worklog | What is planned, what shipped, and what still needs verification? | [`worklog/`](worklog/README.md) |

## Current release snapshot

| Signal | Current value |
| --- | --- |
| Product | LXC-BRM Build Manager |
| Release line | `0.1.2` |
| Tagged local release | `release-2026-08-16` |
| Platform | macOS 15 or later |
| Implementation | Swift 6, SwiftUI, AppKit, Foundation, XCTest |
| Third-party packages | None; the app uses system frameworks only |
| Release artifact | `build-release/version/LXC-BRM-YYYY-MM-DD.dmg` locally |
| Verification command | `xcodebuild -project LXC-BRM/LXC-BRM.xcodeproj -scheme LXC-BRM -configuration Debug test` |

The tracked release contract is kept beside the generated output in [`build-release/version/README.md`](build-release/version/README.md). Generated `.app` and `.dmg` files are ignored by Git so local artifacts do not become source files.

## What the app brings

### Build workspace

The Build workspace is the product's center of gravity. It discovers shell scripts from a repository's `/build/scripts` folder, shows script and location state, runs local scripts, streams stdout and stderr, and exposes stop, refresh, log export, history, and quick actions. The reference concept is kept here:

![Build Console concept](context/concepts-designs/Build-Console-Screen-Concept-02a.png)

The current Build screen record is [`worklog/BuildScreen-plan-todo.md`](worklog/BuildScreen-plan-todo.md). It is an execution record, not a marketing promise: completed items are marked only when the matching behavior exists in the codebase.

### Release support

The release surface connects the native Xcode project to a repeatable local artifact flow:

```text
Xcode project -> Debug or Release build -> staged .app -> local .dmg -> version/
```

The script [`build-release/scripts/release.sh`](build-release/scripts/release.sh) builds with signing disabled for local staging, copies the app into `version/staging/`, and creates a dated DMG in `version/`. Distribution signing and notarization remain separate release concerns and are not implied by the local artifact.

### Context for people and AI tools

The Context area is the reasoning layer. It keeps the requirements input, the current architecture, operating rules, dated decisions, and visual references in one place so an AI tool can learn the project before proposing or changing code.

The important rule is precedence: recorded decisions describe the implementation path when they differ from the original requirements input. The mismatch stays visible; it is not silently erased.

### Frameworks and shared ideas

The Frameworks area is a curated inventory and extension boundary, not a hidden package dump. The current app has no third-party dependency package to update. When a framework, SDK, adapter, or package is introduced, its version, source, compatibility, consumer, and update date belong in [`frameworks/README.md`](frameworks/README.md).

The Shared area is where portable conventions, reusable snippets, and cross-feature ideas can be recorded before they become app-specific code. It is a place for sharing and alignment, not a second source of truth for feature progress.

### Worklog and workload mapping

The Worklog area is the delivery ledger. The master dated todo tracks the release-wide phases, while feature plans capture the deeper checklist for a single screen or pass. Daily worklogs explain what actually changed and what was verified.

The mapping is deliberate:

```text
requirements -> decisions -> master todo -> feature plan -> code -> verification -> worklog story
```

Start with [`worklog/README.md`](worklog/README.md), then use the [master todo](worklog/todo-2026-08-16.md) to find the active phase and the relevant feature plan.

## Documentation map

### Build and release

| File | Purpose |
| --- | --- |
| [`build-release/README.md`](build-release/README.md) | Canonical Debug, Release, and DMG commands. |
| [`build-release/USER_GUIDE.md`](build-release/USER_GUIDE.md) | Human-facing repository, build, logs, history, and preferences guide. |
| [`build-release/projects.json`](build-release/projects.json) | Example project/script mapping used as a configuration template. |
| [`build-release/scripts/`](build-release/scripts/) | Build and packaging entry points. |
| [`build-release/logs/README.md`](build-release/logs/README.md) | Explains support logs versus per-repository application logs. |
| [`build-release/version/README.md`](build-release/version/README.md) | Release artifact staging contract. |

### Context

| File | Purpose |
| --- | --- |
| [`context/README.md`](context/README.md) | How to read the context set and use it for AI-assisted work. |
| [`context/requirements.md`](context/requirements.md) | Functional requirements input retained in the repository. |
| [`context/architecture.md`](context/architecture.md) | Current UI, workspace, documentation, and decision architecture. |
| [`context/rules-context.md`](context/rules-context.md) | Rules that keep the workspace coherent. |
| [`context/decisions/`](context/decisions/) | Dated records of choices that override or clarify the input. |
| [`context/concepts-designs/`](context/concepts-designs/) | Screens, mockups, and the source requirements PDF. |
| [`context/diagrams/`](context/diagrams/) | Self-contained SVG maps for system context, runtime architecture, and release flow. |

### Frameworks, shared, and worklog

| Area | Entry point | Contents |
| --- | --- | --- |
| Frameworks | [`frameworks/README.md`](frameworks/README.md) | System framework matrix and future package/adapter notes. |
| Shared | [`shared/README.md`](shared/README.md) | Reusable conventions and cross-feature ideas. |
| Worklog | [`worklog/README.md`](worklog/README.md) | Tracking rules and file ownership. |
| Master tracker | [`worklog/todo-2026-08-16.md`](worklog/todo-2026-08-16.md) | Current release checklist and phase status. |
| Build screen | [`worklog/BuildScreen-plan-todo.md`](worklog/BuildScreen-plan-todo.md) | Build workspace execution record. |
| Preferences | [`worklog/Plan-PreferenceScreen-todo.md`](worklog/Plan-PreferenceScreen-todo.md) | Preferences design and wiring plan. |
| Window layout | [`worklog/Plan-WindowLayout-todo.md`](worklog/Plan-WindowLayout-todo.md) | Layout and View menu pass. |
| Context architecture visuals | [`worklog/Plan-ContextArchitectureVisuals-todo.md`](worklog/Plan-ContextArchitectureVisuals-todo.md) | SVG diagrams and documentation wiring pass. |
| Code refactoring and reusability | [`worklog/Plan-CodeRefactoring-Reusability-todo.md`](worklog/Plan-CodeRefactoring-Reusability-todo.md) | Code structure, dependency seams, feature extraction, and reuse pass. |
| Daily narrative | [`worklog/worklog-2026-08-16.md`](worklog/worklog-2026-08-16.md) | What changed and how it was verified. |
| Archived plan | [`worklog/BuildScreen-plan-todo_OLD.md`](worklog/BuildScreen-plan-todo_OLD.md) | Historical plan retained for traceability; not an active tracker. |

## How to use this folder

### Before changing code

1. Read this handbook.
2. Read [`context/rules-context.md`](context/rules-context.md) and [`context/architecture.md`](context/architecture.md).
3. Read the relevant requirement and decision records.
4. Find the task in [`worklog/todo-2026-08-16.md`](worklog/todo-2026-08-16.md) or add it there before implementation.

### When finishing a task

1. Update the matching feature plan or master todo only after the behavior exists.
2. Mark a checklist item `[x]` only when it is implemented and verified at the level the item claims.
3. Add a short explanation to the dated worklog.
4. Update context when the architecture, rules, release path, or product decision changes.

### When preparing a release

1. Confirm the master todo and feature plan reflect the actual code.
2. Run the Debug build and tests.
3. Run [`release.sh`](build-release/scripts/release.sh) for the local Release app and DMG.
4. Inspect the generated artifact under `build-release/version/`.
5. Record the result in the worklog and use a dated release tag when the release is intentionally captured.

## Honest boundaries

- A GitHub URL can be scanned, but it cannot execute a build until it is available as a local checkout.
- The local release script produces an unsigned artifact for inspection and staging; production signing and notarization are separate.
- The master worklog remains authoritative for open performance, stress, settings, and GUI-hardening work.
- The original requirements include a Tauri/Rust/React proposal, but the recorded decision is native Swift/SwiftUI/AppKit. The decision log explains why.
- Empty framework and shared folders are intentional extension points until a real reusable asset belongs there.

## Related entry points

- [Repository landing page](../../README.md)
- [App product README](../README.md)
- [Build and release](build-release/README.md)
- [User guide](build-release/USER_GUIDE.md)
- [Context](context/README.md)
- [Context diagrams](context/diagrams/README.md)
- [Worklog](worklog/README.md)
