# LXC-BRM

<p align="center">
  <strong>Build Manager for macOS</strong><br>
  Discover repository scripts, run builds, read the output, and carry the result into a repeatable release flow.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS%2015%2B-111827?logo=apple&logoColor=white" alt="Platform: macOS 15 or later">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/SwiftUI%20%2B%20AppKit-native-2563EB" alt="Native SwiftUI and AppKit">
  <img src="https://img.shields.io/badge/release-0.1.2-7C3AED" alt="Release 0.1.2">
  <img src="https://img.shields.io/badge/third--party%20dependencies-none-059669" alt="No third-party dependencies">
  <img src="https://img.shields.io/badge/license-MIT-10B981" alt="MIT license">
</p>

<p align="center">
  <a href="#the-idea">The idea</a> |
  <a href="#what-ships">What ships</a> |
  <a href="#quick-start">Quick start</a> |
  <a href="#repository-contract">Repository contract</a> |
  <a href="Support/README.md">Support handbook</a>
</p>

---

## The idea

Every project eventually grows a collection of shell commands that only the team knows how to run. LXC-BRM turns those commands into a visible workspace without replacing the scripts or hiding the underlying process.

Point the app at a local repository or a GitHub repository. LXC-BRM looks for the build contract, presents the available scripts, runs local scripts in the repository root, and keeps the output and history close enough to inspect when a release needs an explanation.

![Build Console concept](Support/context/concepts-designs/Build-Console-Screen-Concept-02a.png)

The concept above is the visual north star for the Build workspace: repositories on the left, build actions and live output in the center, and status, history, and quick actions in the detail panel.

## What ships

| Capability | Behavior |
| --- | --- |
| Repository discovery | Add local folders or GitHub URLs, validate the source, and keep recent repositories. |
| Build detection | Scan `/build/scripts` for shell scripts and executable files, with clear missing and empty states. |
| Build execution | Launch local scripts through the configured shell (default `/bin/zsh`) with the repository root as the working directory. |
| Live console | Stream stdout and stderr with timestamps, search, filters, line numbers, wrapping, and auto-scroll. |
| Build history | Persist per-repository runs, statuses, durations, logs, success rate, and average duration. |
| Repository workspace | Switch between repositories, pin favorites, inspect branch/source information, and keep history isolated. |
| Release support | Build Debug or Release configurations and stage a local `.app` plus `.dmg` through the Support release script. |
| Preferences | Configure repository scanning, execution, logs, appearance, notifications, and advanced behavior. |

### Product flow

1. Add a repository from the sidebar.
2. LXC-BRM checks the repository and discovers `/build/scripts`.
3. Choose a script and run it locally.
4. Watch live output while the process runs, or stop it and preserve the partial log.
5. Review the result in Logs, History, or Overview.
6. Use the release flow when the build is ready to become a distributable artifact.

GitHub sources can be inspected through the contents API, but only local checkouts can execute a script. This boundary is intentional and documented in the [Build screen plan](Support/worklog/BuildScreen-plan-todo.md).

## Quick start

### Build from Xcode

1. Open `LXC-BRM.xcodeproj` in Xcode.
2. Select the `LXC-BRM` scheme and `My Mac`.
3. Press `Cmd+B` to build or `Cmd+R` to run.

### Build from the terminal

Run from the repository root:

```sh
xcodebuild -project LXC-BRM/LXC-BRM.xcodeproj -scheme LXC-BRM -configuration Debug build
xcodebuild -project LXC-BRM/LXC-BRM.xcodeproj -scheme LXC-BRM -configuration Debug test
```

The app currently targets macOS 15 and uses Swift 6 with system frameworks only.

## Repository contract

For the default scan, a project looks like this:

```text
your-repository/
  build/
    scripts/
      build-ios.sh
      release.sh
    logs/
```

LXC-BRM treats `build/scripts` as the standard discovery location. A local script is executed with the repository root as its working directory. Logs are written back to that repository's `build/logs` folder and can also be exported through the app.

## Data and release locations

| Data | Location |
| --- | --- |
| Recent repositories | `~/Library/Application Support/LXC-BRM/projects.json` |
| Build history | `~/Library/Application Support/LXC-BRM/build-history.json` |
| Build workspace state | `~/Library/Application Support/LXC-BRM/build-workspace-state.json` |
| Preferences | `~/Library/Application Support/LXC-BRM/preferences.json` |
| Repository logs | `<repository>/build/logs/` |
| Release staging | `Support/build-release/version/` |

## Project documentation

The [Support handbook](Support/README.md) is the main map for the project. It explains what each support area owns and how the files work together.

| Need | Read |
| --- | --- |
| Use the app | [User guide](Support/build-release/USER_GUIDE.md) |
| Package a release | [Build and release README](Support/build-release/README.md) |
| Understand requirements | [Requirements](Support/context/requirements.md) |
| Understand architecture | [Architecture](Support/context/architecture.md) |
| Understand decisions | [Decision log](Support/context/decisions/decision-2026-08-16.md) |
| Follow current work | [Master worklog](Support/worklog/todo-2026-08-16.md) |
| Read the Build screen record | [Build screen plan](Support/worklog/BuildScreen-plan-todo.md) |

## Project status

The native app builds and its Xcode test target passes locally. The remaining work is tracked explicitly in the master worklog, including performance measurement, broader stress testing, and final GUI hardening. The documentation does not mark those items complete merely because the project compiles.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) and the [Code of Conduct](CODE_OF_CONDUCT.md). When a code change changes the product contract, update the relevant Support context and worklog entry in the same change.

## License

LXC-BRM is released under the [MIT License](LICENSE).
