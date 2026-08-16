# LXC Build & Release Manager

<p align="center">
  <strong>A native macOS workspace for turning repository build scripts into a calm, observable release flow.</strong>
</p>

<p align="center">
  <a href="LXC-BRM/README.md">Product guide</a> |
  <a href="LXC-BRM/Support/README.md">Support handbook</a> |
  <a href="LXC-BRM/Support/build-release/USER_GUIDE.md">User guide</a> |
  <a href="LXC-BRM/Support/context/requirements.md">Requirements</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2015%2B-111827?logo=apple&logoColor=white" alt="Platform: macOS 15 or later">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/UI-SwiftUI%20%2B%20AppKit-2563EB" alt="SwiftUI and AppKit">
  <img src="https://img.shields.io/badge/version-0.1.2-7C3AED" alt="Version 0.1.2">
  <img src="https://img.shields.io/badge/dependencies-none-059669" alt="No third-party dependencies">
  <img src="https://img.shields.io/badge/license-MIT-10B981" alt="MIT license">
</p>

## Why this repository exists

LXC-BRM gives local repositories a consistent build and release surface. It discovers scripts under `/build/scripts`, runs local commands as managed subprocesses, streams timestamped output, persists build history, and keeps the release artifacts and project knowledge organized beside the app.

The repository has two layers:

| Layer | Role |
| --- | --- |
| `LXC-BRM/` | The native SwiftUI/AppKit macOS application and its Xcode project. |
| `LXC-BRM/Support/` | The operating handbook for builds, releases, context, frameworks, shared conventions, and worklogs. |

## Start here

1. Read the [product guide](LXC-BRM/README.md) for the application capabilities and local setup.
2. Read the [Support handbook](LXC-BRM/Support/README.md) for the full project map and release story.
3. Read the [user guide](LXC-BRM/Support/build-release/USER_GUIDE.md) for the repository and build workflow.
4. Read the [context rules](LXC-BRM/Support/context/rules-context.md) before changing architecture or documentation conventions.

## Build and test

Run these commands from the repository root:

```sh
xcodebuild -project LXC-BRM/LXC-BRM.xcodeproj -scheme LXC-BRM -configuration Debug build
xcodebuild -project LXC-BRM/LXC-BRM.xcodeproj -scheme LXC-BRM -configuration Debug test
```

Open `LXC-BRM/LXC-BRM.xcodeproj` in Xcode, choose the `LXC-BRM` scheme and `My Mac`, then use `Cmd+B` to build or `Cmd+R` to run.

## Repository map

| Area | Purpose | Entry point |
| --- | --- | --- |
| `LXC-BRM/App/` | SwiftUI views, models, and services. | [App source](LXC-BRM/App/) |
| `LXC-BRM/Tests/` | Xcode unit and integration-level workspace tests. | [BuildWorkspaceTests.swift](LXC-BRM/Tests/BuildWorkspaceTests.swift) |
| `LXC-BRM/Support/build-release/` | Build scripts, release packaging, logs guidance, and artifact staging. | [Build and release](LXC-BRM/Support/build-release/README.md) |
| `LXC-BRM/Support/context/` | Requirements, architecture, decisions, rules, and design references. | [Context](LXC-BRM/Support/context/README.md) |
| `LXC-BRM/Support/frameworks/` | Framework inventory and future adapter/package notes. | [Frameworks](LXC-BRM/Support/frameworks/README.md) |
| `LXC-BRM/Support/shared/` | Shared workspace conventions and reusable support ideas. | [Shared](LXC-BRM/Support/shared/README.md) |
| `LXC-BRM/Support/worklog/` | Master checklist, feature plans, and dated execution notes. | [Worklog](LXC-BRM/Support/worklog/README.md) |

## Release line

The current product line is `0.1.2`. The dated local release tag is `release-2026-08-16`; the repeatable packaging flow is documented in [build-release](LXC-BRM/Support/build-release/README.md) and implemented by [`release.sh`](LXC-BRM/Support/build-release/scripts/release.sh).

The release process produces an unsigned local `.app` and a `.dmg` under `LXC-BRM/Support/build-release/version/`. Those generated artifacts are intentionally ignored by Git; the tracked `version/README.md` explains the staging contract.

## License

This project is available under the [MIT License](LXC-BRM/LICENSE).
