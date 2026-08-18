# Build and Release

<p align="center">
  <img src="https://img.shields.io/badge/release%20line-0.1.2-7C3AED" alt="Release line 0.1.2">
  <img src="https://img.shields.io/badge/artifact-local%20DMG-2563EB" alt="Local DMG artifact">
  <img src="https://img.shields.io/badge/signing-local%20only-F59E0B" alt="Local signing only">
</p>

This folder owns the operational path from the Xcode project to a local release artifact. It contains the command scripts, the example project mapping, the release staging area, and the documentation a human needs to run the flow safely.

For the branded packaging notes, see [`LEXVORA-PACKAGE.md`](LEXVORA-PACKAGE.md).

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
| `LEXVORA-PACKAGE.md` | Brand-facing package notes and website pointer. |

## Canonical commands

Run from the repository root, not from this folder:

```sh
xcodebuild -project LXC-Build-Release-Manager.xcodeproj -scheme LXC-Build-Release-Manager -configuration Debug build
xcodebuild -project LXC-Build-Release-Manager.xcodeproj -scheme LXC-Build-Release-Manager -configuration Debug test
```

The same project can be opened in Xcode with the `LXC-Build-Release-Manager` scheme and `My Mac` destination.

## Local release flow

The repeatable packaging command is:

```sh
./Support/build-release/scripts/release.sh
```

The script:

1. Builds the `Release` configuration with `CODE_SIGNING_ALLOWED=NO` and `CODE_SIGNING_REQUIRED=NO`.
2. Places the app in `Support/build-release/version/staging/`.
3. Creates `Support/build-release/version/LXC-Build-Release-Manager-<version>.dmg` with `hdiutil`.
4. Replaces the same-day DMG if the command is run again.

This is a local inspection and staging flow. A production distribution still needs a Developer ID signing identity, notarization, and release-specific validation before the DMG is shared outside the development machine.

## Requirement and decision precedence

- The functional requirements are preserved in [`../context/requirements.md`](../context/requirements.md).
- Recorded implementation decisions are preserved in [`../context/decisions/`](../context/decisions/).
- Delivery tracking starts at [`../worklog/BRM-Plan-todo.md`](../worklog/BRM-Plan-todo.md); the release flow itself is owned by [`../worklog/Plan-ReleasePackaging-todo.md`](../worklog/Plan-ReleasePackaging-todo.md).
- This folder does not own a competing feature todo file.

If a requirement and a decision disagree, follow the decision and keep the difference visible in Context.

## Release checklist

- [ ] Confirm the intended version and release notes.
- [ ] Run the Debug build and test commands.
- [ ] Inspect the Release app bundle.
- [ ] Run `release.sh` and inspect the DMG in `version/`.
- [ ] Confirm signing and notarization requirements before external distribution.
- [ ] Record the result in the [verification ledger](../worklog/Plan-QualityVerification-todo.md) and tick the matching item in [`Plan-ReleasePackaging-todo.md`](../worklog/Plan-ReleasePackaging-todo.md).

For the user-facing behavior of the app, continue to the [User Guide](USER_GUIDE.md). For the complete project map, return to the [Support Handbook](../README.md).

## Releasing, and how the in-app updater finds a build

The `.dmg` is **not** committed. `/Support/build-release/version/` and `*.dmg` are both ignored,
which is the standard arrangement: binaries belong in GitHub Releases, not in git history. The
`version/` folder is the local staging area for the artifact you are about to publish.

```bash
Support/build-release/scripts/release.sh                     # build + stage the .dmg locally
Support/build-release/scripts/release.sh --publish           # also publish it to the Stable channel
Support/build-release/scripts/release.sh --publish --prerelease   # publish it to the Beta channel
```

The artifact is named from the built app's `CFBundleShortVersionString`, so bumping
`MARKETING_VERSION` in the Xcode project is what drives the release version:

```
LXC-Build-Release-Manager-0.1.2.dmg      tag v0.1.2
```

Publishing needs the [GitHub CLI](https://cli.github.com), authenticated with `gh auth login`.
Re-running `--publish` for a tag that already exists uploads the asset to that release and
replaces any previous copy rather than failing.

### What the app reads

The in-app update checker (Preferences → General) reads:

```
https://api.github.com/repos/Sage2vish/LXC-Build-Release-Manager/releases
```

- **Stable** offers the newest release that is not a prerelease. **Beta** also offers prereleases.
  Drafts are never offered on either channel.
- The tag is compared against the running `CFBundleShortVersionString`, so tags must be versions
  (`v0.1.2` or `0.1.2`). A tag that is not a version — `release-2026-08-16`, for example — is
  ignored rather than treated as newer.
- When a `.dmg` is attached, the app links straight to it; otherwise it links to the release page.

Until a Release is published, the checker correctly reports "up to date", because there is
nothing in the feed to compare against.
