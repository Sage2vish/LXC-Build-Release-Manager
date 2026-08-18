# Plan — Release & packaging

> Everything between a green build and something a person can install: the release script, the
> staged `.app`, the `.dmg`, the tag, and the documents that ship with it.
>
> What the in-app updater does with a published release belongs to
> [`Plan-Updates-todo.md`](Plan-Updates-todo.md). This plan owns producing the artifact; that one
> owns discovering it.

Consolidated from the retired `todo-2026-08-16.md` (Phase 7, Decision Overrides) and
`worklog-2026-08-16.md` (release staging notes and follow-ups).

## The flow

```text
LXC-Build-Release-Manager.xcodeproj
   └─ Release build (signing disabled)
        └─ version/staging/LXC-Build-Release-Manager.app
             └─ version/LXC Build Release Manager-<version>.dmg
                  └─ optional: gh release create  →  GitHub Releases
```

The entry point is `Support/build-release/scripts/release.sh`. Run it from the repository root:

```sh
./Support/build-release/scripts/release.sh              # build + stage + dmg
./Support/build-release/scripts/release.sh --publish     # also publish to GitHub Releases
./Support/build-release/scripts/release.sh --publish --prerelease   # Beta channel
```

## 01. Deliverables — shipped

- [x] Build and packaging instructions — [`build-release/README.md`](../build-release/README.md).
- [x] User guide / quick start — [`build-release/USER_GUIDE.md`](../build-release/USER_GUIDE.md).
- [x] Configuration template `projects.json`, kept in `build-release/`.
- [x] A real tagged release with a staged `.dmg`: the local release script produced the artifact
      and the tree was tagged `release-2026-08-16`.
- [x] `version/` documented as the staging contract —
      [`version/README.md`](../build-release/version/README.md).

## 02. Artifact naming and publication

- [x] The `.dmg` is named from the built app's `CFBundleShortVersionString`
      (`LXC-Build-Release-Manager-0.1.2.dmg`, tag `v0.1.2`) rather than from a date, because the updater compares
      release tags against that version.
- [x] `--publish` creates the GitHub Release and attaches the `.dmg` through the GitHub CLI;
      re-publishing an existing tag replaces the asset instead of failing.
- [x] `--prerelease` puts the build on the Beta channel.
- [x] Generated binaries stay out of git: `Support/build-release/version/` and `*.dmg` are
      ignored. Binaries belong in Releases, not in history.
- [x] The staged DMG mounts with the branded background folder, the app bundle, the
      `Applications` link, and the package README visible at the top level.
- [ ] **Nothing is published yet.** The releases feed is empty, and the only tag,
      `release-2026-08-16`, is not a version string, so the updater ignores it rather than
      misreading it as newer. Publishing the first real release is the open step.

## 03. Signing and distribution

- [ ] Decide on code signing for Release; it is currently unconfigured, and Debug builds run with
      `CODE_SIGNING_ALLOWED=NO`. *(Shares a boundary with
      [`Plan-XcodeProject-todo.md`](Plan-XcodeProject-todo.md) section 02, which owns the build
      settings themselves.)*
- [ ] Developer ID signing and notarization for anything distributed outside this machine. The
      current artifact is deliberately an unsigned, inspectable local build.
- [ ] State plainly in the release notes that an unsigned build will be quarantined by Gatekeeper,
      until signing exists.

## 04. The product releases itself

The app asks every project for `build/scripts/*.sh`. This repository now honours that contract, so
the app can open its own repository and run its own build, test and release commands. One release
path, exercised by the product it releases — and the first honest GUI test subject the project has
had.

- [x] Add `build/scripts/` to this repository, tracked in git while the rest of `build/` stays
      ignored.
- [x] `build-debug.sh` and `run-tests.sh` wrap the canonical `xcodebuild` invocations.
- [x] `release-stage.sh` and `release-publish.sh` wrap
      [`Support/build-release/scripts/release.sh`](../build-release/scripts/release.sh), so there
      is one implementation and the script folder is a menu, not a fork of it.
- [x] `update-plan-index.sh` exposes the plan-index generator the same way.
- [x] Verified from the terminal: `build-debug.sh` → `BUILD SUCCEEDED`, `run-tests.sh` → 80 tests,
      0 failures.
- [ ] Run all five through the **app's Build tab** rather than the terminal, and record the result
      as GUI coverage in
      [`Plan-QualityVerification-todo.md`](Plan-QualityVerification-todo.md) section 04.
- [ ] Confirm the app writes `build/logs/build-*.log` into this repository and that git ignores
      them, so dogfooding never dirties the working tree.
- [ ] Decide whether `release-publish.sh` should stay in the menu at all: a one-click publish is
      convenient and irreversible in equal measure, and the Build tab has no confirmation step.

## 05. Release checklist maintenance

- [ ] Expand the release checklist as the packaging flow matures, rather than letting the script
      become the only description of it.
- [ ] Record every intentional release in the verification ledger in
      [`Plan-QualityVerification-todo.md`](Plan-QualityVerification-todo.md), with the build and
      test evidence that preceded it.
- [ ] Decide whether `projects.json` stays a static template in `build-release/` or becomes a live
      file the app reads and writes. Preferences → Advanced offers an "Open `projects.json`"
      button that assumes the latter. *(Open question 13 in
      [`Plan-PreferenceScreen-todo.md`](Plan-PreferenceScreen-todo.md).)*

## Storage decisions in effect

Carried from the decision log so the packaging rules stay visible next to the flow they govern:

1. `projects.json` under `build-release/` is a configuration **template**. The running app's own
   recent-repositories, history, preferences and workspace state live in
   `~/Library/Application Support/LXC-Build-Release-Manager/`, never in the repository.
2. Repository logs stay repository-local under `<repository>/build/logs/`; they are part of the
   product contract, not app data.
3. A PDF-versus-decision conflict is recorded in `context/decisions/` before it is built around.

## Non-Goals

- No CI-driven release; publication stays a deliberate local act.
- No Sparkle or third-party updater framework — see `Plan-Updates-todo.md` for why the GitHub
  Releases feed was chosen instead.
- No App Store distribution path.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| 01 — Deliverables | 5 / 5 | Done |
| 02 — Artifact naming and publication | 4 / 5 | First real release not yet published |
| 03 — Signing and distribution | 0 / 3 | Open |
| 04 — Checklist maintenance | 0 / 3 | Ongoing |
| **Total** | **9 / 16** | **In progress** |
