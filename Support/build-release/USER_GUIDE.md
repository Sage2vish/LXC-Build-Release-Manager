# LXC Build Release Manager — User Guide

This guide covers the app's human-facing workflow. For packaging commands and release staging, see [Build and Release](README.md). For the full project map, see the [Support Handbook](../README.md).

## What it does

Point the app at a repository (local folder or GitHub URL). It looks for a `/build` folder, lists the `.sh` scripts it finds in `/build/scripts/`, and lets you run local scripts with live output and saved history.

## The repository contract

A project only needs this much structure to be fully usable:

```text
your-repository/
  build/
    scripts/
      build-debug.sh
      run-tests.sh
      release-stage.sh
    logs/           # created for you on the first run
```

Every `.sh` file in `build/scripts/` becomes a runnable command, labelled from its filename
(`build-debug.sh` → "build-debug"). Scripts run with the **repository root** as the working
directory, so paths inside them can stay relative. Each run writes
`build/logs/build-YYYY-MM-DD-HH-MM-SS.log`.

Nothing about the scripts themselves is special: they are the commands the team already runs by
hand. The app makes them visible, runnable, and recorded — it does not replace them.

## This repository is its own example

LXC Build Release Manager follows the contract it asks of everyone else, which is the fastest way
to see it working: **add this repository to the app** and its own commands appear in the Build tab.

| Script | What running it does |
| --- | --- |
| `build-debug.sh` | Debug build of the app itself |
| `run-tests.sh` | The full unit-test suite, summarised to pass/fail lines |
| `release-stage.sh` | Release build, staged `.app`, and a version-named `.dmg` under `Support/build-release/version/` — nothing is published |
| `release-publish.sh` | The same, then a GitHub Release carrying the `.dmg` — the feed the in-app updater reads. Needs the GitHub CLI, authenticated. Pass `--prerelease` for the Beta channel |
| `update-plan-index.sh` | Recounts every delivery plan and rewrites the generated tables in the plan index |

So the release of this app can be driven from this app: pick `release-stage.sh`, watch the build
stream, and the artifact appears staged and ready to inspect. The same scripts are what CI and the
terminal run, so there is one release path rather than three that drift apart.

## Quick Start

1. Launch the app.
2. Click **Add Repository** (top-right of the sidebar).
3. Either:
   - **Choose Local Folder…** and pick a repo on disk that has a `/build/scripts/` folder with `.sh` files, or
   - Paste a **GitHub URL** like `https://github.com/user/repo` and click **Add GitHub Repository**.
4. The repo appears in the sidebar and is selected automatically. The detail pane scans it and shows what it found:
   - **Connected** (green) — scripts detected, ready to run
   - **No /build folder** — add a `/build` folder with a `scripts/` subfolder to the repo root
   - **No scripts found** — `/build/scripts/` exists but has no `.sh` files
   - **Unreachable** — GitHub repo/URL couldn't be reached

## Running a Build

Only local repositories can execute scripts. A GitHub URL can be scanned, but it has no local checkout against which LXC Build Release Manager can safely run the configured shell.

1. Go to the **Build** tab.
2. Click **Run** next to a script. Output streams live below, each line timestamped.
3. Click **Cancel** to stop a running build; partial output is kept and the run is recorded as "Cancelled".
4. When it finishes, the result (success/failed/cancelled + duration) is saved automatically.

## Logs

The **Logs** tab shows the live output of a running build, or the saved log of a past build (pick one from the **History** tab to jump here). You can:
- **Search** the log — matches are highlighted, with a count and next/previous navigation.
- **Filter** by Errors / Warnings / Info.
- **Export** the current log to a file (defaults to your Downloads folder).

Saved logs live on disk in the repo's own `/build/logs/` folder, named `build-YYYY-MM-DD-HH-MM-SS.log`.

## History & Overview

- **History** — every build run for this repo, most recent first, with status and duration. Click one to view its log.
- **Overview** — repo info, total builds, success rate, average duration, most recent run, and last failure (if any).

## Managing Repositories

- **Pin** a repo (pin icon in the sidebar row) to keep it at the top of the list.
- **Remove** a repo (✕ icon in the sidebar row, or the Remove button in the repo's **Settings** tab) — this only clears it from the app's list, it never touches the folder on disk.
- Repositories and their build history persist across app restarts (stored locally under `~/Library/Application Support/LXC-Build-Release-Manager/`).

## Appearance

The app follows your Mac's system light/dark mode automatically. The Preferences surface also exposes theme, console, repository, execution, notification, and layout settings. Any setting still marked open in the [Preferences plan](../worklog/Plan-PreferenceScreen-todo.md) remains subject to verification.
