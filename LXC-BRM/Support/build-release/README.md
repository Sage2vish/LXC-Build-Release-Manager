# Build and Release

<p align="center">
  <img src="https://img.shields.io/badge/release%20line-0.1.2-7C3AED" alt="Release line 0.1.2">
  <img src="https://img.shields.io/badge/artifact-local%20DMG-2563EB" alt="Local DMG artifact">
  <img src="https://img.shields.io/badge/signing-local%20only-F59E0B" alt="Local signing only">
</p>

This folder owns the operational path from the Xcode project to a local release artifact. It contains the command scripts, the example project mapping, the release staging area, and the documentation a human needs to run the flow safely.

## Ownership map

| Path | Responsibility |
| --- | --- |
| `scripts/build-ios.sh` | Example iOS build entry point for repositories managed by the app. |
| `scripts/build-android.sh` | Example Android build entry point for repositories managed by the app. |
| `scripts/release.sh` | Builds the macOS app and creates a dated local DMG. |
| `projects.json` | Example configuration template showing repository/script mapping. |
| `logs/` | Documentation for release-support logs; application run logs live in the target repository. |
| `version/` | Final local artifact staging, including `version/staging/`. |
| `USER_GUIDE.md` | Human-facing guide to the app workflow. |

## Canonical commands

Run from the repository root, not from this folder:

```sh
xcodebuild -project LXC-BRM/LXC-BRM.xcodeproj -scheme LXC-BRM -configuration Debug build
xcodebuild -project LXC-BRM/LXC-BRM.xcodeproj -scheme LXC-BRM -configuration Debug test
```

The same project can be opened in Xcode with the `LXC-BRM` scheme and `My Mac` destination.

## Local release flow

The repeatable packaging command is:

```sh
./LXC-BRM/Support/build-release/scripts/release.sh
```

The script:

1. Builds the `Release` configuration with `CODE_SIGNING_ALLOWED=NO` and `CODE_SIGNING_REQUIRED=NO`.
2. Places the app in `Support/build-release/version/staging/`.
3. Creates `Support/build-release/version/LXC-BRM-YYYY-MM-DD.dmg` with `hdiutil`.
4. Replaces the same-day DMG if the command is run again.

This is a local inspection and staging flow. A production distribution still needs a Developer ID signing identity, notarization, and release-specific validation before the DMG is shared outside the development machine.

## Requirement and decision precedence

- The functional requirements are preserved in [`../context/requirements.md`](../context/requirements.md).
- Recorded implementation decisions are preserved in [`../context/decisions/`](../context/decisions/).
- The active checklist is [`../worklog/todo-2026-08-16.md`](../worklog/todo-2026-08-16.md).
- This folder does not own a competing feature todo file.

If a requirement and a decision disagree, follow the decision and keep the difference visible in Context.

## Release checklist

- [ ] Confirm the intended version and release notes.
- [ ] Run the Debug build and test commands.
- [ ] Inspect the Release app bundle.
- [ ] Run `release.sh` and inspect the DMG in `version/`.
- [ ] Confirm signing and notarization requirements before external distribution.
- [ ] Record the result in the dated worklog and update the master tracker.

For the user-facing behavior of the app, continue to the [User Guide](USER_GUIDE.md). For the complete project map, return to the [Support Handbook](../README.md).
