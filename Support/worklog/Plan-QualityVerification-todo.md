# Plan — Quality & verification

> The product-wide quality plan. It owns the **non-functional** targets, the test-suite state, how
> much of the app has actually been click-tested, and the standing caveats that are true of the
> product rather than of one region.
>
> Correctness of a single surface belongs to that surface's plan. This file only asks: *is the
> claim verified, and at what level?*

Consolidated from the retired `todo-2026-08-16.md` (Phase 6, Known Gaps) and
`worklog-2026-08-16.md` (verification evidence, performance measurements, resilience coverage).

## The verification levels

A plan's `[x]` is only as strong as the level it was checked at. These are the levels used
across every plan in this folder.

| Level | Means |
| --- | --- |
| **Compiled** | `xcodebuild ... build` → `BUILD SUCCEEDED`. Says nothing about behaviour. |
| **Traced** | The code path was read end to end against a real repository's `/build/scripts/`. |
| **Tested** | An automated test in the Xcode test target asserts it. |
| **Click-tested** | Exercised in the running GUI, with the result observed on screen or on disk. |

A compile never closes a GUI, performance, stress, or release-distribution item.

## Work plan

## 01. Non-functional targets — measured, not assumed

Requirements §6. Every number here was measured rather than estimated.

- [x] **Launch under 2 seconds.** Measured 1.09s / 1.10s / 1.07s across three runs, process start
      to window on screen.
- [x] **Repository scan under 5 seconds.** A 60-script repository and ten back-to-back repository
      scans are both asserted under 5s in `PerformanceAndResilienceTests`.
- [x] **5–10+ connected repositories without visible slowdown.** Ten repositories scan, persist,
      reload, and keep per-repository workspace state without cross-talk.
- [x] **Minimal dependencies.** No third-party packages; Foundation, SwiftUI and AppKit only.
- [x] **Offline support.** Logs and history are local files and open with no network; a GitHub
      scan failure is caught and shown as "Unreachable" instead of crashing.
- [x] **v1 scope check.** Repository input and history, `/build` detection, button generation,
      build execution with log streaming, multi-project support, a native `.app`, and a basic
      dashboard are all present. None of the out-of-scope items — GitHub Actions, webhooks,
      Slack/email, Docker, Windows/Linux, analytics charts — were built.

## 02. Resilience coverage

Adversarial cases covered by tests rather than assumed, in `PerformanceAndResilienceTests`.

- [x] Missing `/build` folder.
- [x] Empty scripts folder.
- [x] A path that never existed.
- [x] A repository deleted between two scans.
- [x] Corrupt `preferences.json` and `build-history.json` — reported through `AppDataError`, and
      the app still starts on defaults.
- [x] GitHub-sourced repositories being scannable but never runnable.

## 03. Test suite state

- [x] Unit coverage exists for repository persistence, build-script scanning, and log parsing.
- [x] Four suites in the target: `BuildWorkspaceTests`, `BuildScreenTests`, `MarkdownTests`,
      `PerformanceAndResilienceTests` — **80 test functions** on the current tree.
- [x] Record a fresh full-suite run. **80 tests, 0 failures**, run on 2026-08-18 after the
      workspace flatten and the codename rename. The earlier figures — 14 at the refactor
      baseline, 21 after the persistence pass, 35 after the preferences audit — were all stale.
- [ ] Add a UI-test target. It is the blocker on `performAccessibilityAudit()` and on any real
      automated click-through. *(Owned by [`Plan-XcodeProject-todo.md`](Plan-XcodeProject-todo.md)
      section 03 — tracked here because it gates this plan.)*

## 04. GUI click-through coverage

The standing caveat used to be "no GUI click-through testing at all". That is no longer true, but
it is also not finished — this is the honest map of which parts have been driven in the running
app.

**Click-tested**

- [x] The three View menu items, confirmed present through an accessibility query, then clicked
      while watching `preferences.json` change on disk.
- [x] Sidebar hide/show, round-tripped and re-verified across **5 out of 5** relaunches after the
      visibility binding was made single-source.
- [x] The Docs tab — file discovery, Preview/Source modes and editing — exercised in the app.
- [x] Window resize measurements taken from the live window: 1853pt → 1513pt minimum with the
      Detail View panel open.

**Not click-tested yet**

- [ ] The Preferences window, tab by tab: change a value, Save, confirm the app behaves and the
      value survives a relaunch.
- [ ] The build flow end to end in the GUI: pick a script, set parameters, run, watch output,
      stop, clear, export the log.
- [ ] Repository add / remove / pin / switch through the sidebar rather than through the stores.
- [ ] The notification surface, since it needs a real user-notification grant to observe.

## 05. Standing caveats

True of the product, not bugs to be fixed silently. Each one names the plan that would own the
change if it were ever made.

1. **GitHub repositories can be scanned but not built.** Running `bash` against a URL is not
    possible without a local checkout. The requirements do not resolve this either; it is an
    explicit product boundary, documented in `context/architecture.md`.
2. **"Total Builds Run" is all-time, not session-scoped.** Requirements §4.1 describes a
    per-session counter. Persisting across restarts is arguably more useful, but it is a
    deliberate deviation. → [`Plan-Tab-Overview-todo.md`](Plan-Tab-Overview-todo.md).
3. **Branch is `—` for GitHub-sourced repositories, and a short SHA on detached HEAD.** Inherent
    to reading `.git/HEAD` from disk without shelling out to `git`.
    → [`Plan-StatusBar-todo.md`](Plan-StatusBar-todo.md).
4. **Release artifacts are unsigned.** The local script stages an inspectable `.dmg`; Developer ID
    signing and notarization are separate work.
    → [`Plan-ReleasePackaging-todo.md`](Plan-ReleasePackaging-todo.md).

## 06. Verification ledger

Dated evidence, kept so a claim can be traced back to the run that produced it.

| Date | What was verified | Result |
| --- | --- | --- |
| 2026-08-16 | Debug build after the app-shell and rename work | `BUILD SUCCEEDED` |
| 2026-08-16 | Debug build re-run after the signing and resource cleanup | `BUILD SUCCEEDED` |
| 2026-08-16 | Refactor baseline: `xcodebuild ... CODE_SIGNING_ALLOWED=NO build` then `... test` | `BUILD SUCCEEDED`, `TEST SUCCEEDED`, 14 tests, 0 failures |
| 2026-08-16 | Scanner logic against a real test repository (`build/scripts/build-demo.sh`) | Scripts found and labelled correctly |
| 2026-08-16 | View menu, sidebar persistence, panel visibility, in the running app | Confirmed; screenshots captured |
| 2026-08-16 | Preferences audit — all 73 stored fields checked for a real consumer | 54 read, 19 unread; see [`Plan-PreferenceScreen-todo.md`](Plan-PreferenceScreen-todo.md) |
| 2026-08-16 | Launch time, three runs | 1.09s / 1.10s / 1.07s |
| 2026-08-16 | Suite after the resilience pass | 35 tests, 0 failures |
| 2026-08-18 | Debug build after the workspace flatten and rename | `BUILD SUCCEEDED` |
| 2026-08-18 | Full suite after the rename — the module and every `@testable import` changed | `TEST SUCCEEDED`, **80 tests, 0 failures** |
| 2026-08-18 | Clean Debug build after `Support/` became a synchronized group | `BUILD SUCCEEDED`; bundle holds only `hi.lproj` and the background asset, 9.2 MB |
| 2026-08-18 | `release.sh` end to end | `LXC-Build-Release-Manager-0.1.2.dmg` staged under `version/` |
| 2026-08-18 | The repository's own `build/scripts/build-debug.sh` and `run-tests.sh` | `BUILD SUCCEEDED`; 80 tests, 0 failures |
| 2026-08-18 | Full suite after the diagnostics log filename change | 80 tests, 0 failures |

The canonical commands:

```sh
xcodebuild -project LXC-Build-Release-Manager.xcodeproj -scheme LXC-Build-Release-Manager -configuration Debug CODE_SIGNING_ALLOWED=NO build
xcodebuild -project LXC-Build-Release-Manager.xcodeproj -scheme LXC-Build-Release-Manager -configuration Debug -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO test
```

- [ ] Add a row here whenever a plan's verification level changes, so evidence never lives only
      in a commit message.

## Non-Goals

- No CI pipeline; verification is local and recorded here by hand until that changes.
- No performance work without a measurement first — a target that is already met is not a task.
- No re-testing of a surface just to raise its level; raise it when the surface changes.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| 01 — Non-functional targets | 6 / 6 | Met and measured |
| 02 — Resilience coverage | 6 / 6 | Covered by tests |
| 03 — Test suite state | 3 / 4 | 80 tests green; UI-test target still open |
| 04 — GUI click-through | 4 / 8 | Half the app is still compile-and-trace only |
| 06 — Verification ledger | 0 / 1 | Ongoing |
| **Total** | **19 / 25** | **In progress** |
