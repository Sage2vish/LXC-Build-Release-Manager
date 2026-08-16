# LXC-BRM Build Manager - User Guide

This guide covers the app's human-facing workflow. For packaging commands and release staging, see [Build and Release](README.md). For the full project map, see the [Support Handbook](../README.md).

## What it does

Point the app at a repository (local folder or GitHub URL). It looks for a `/build` folder, lists the `.sh` scripts it finds in `/build/scripts/`, and lets you run local scripts with live output and saved history.

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

Only local repositories can execute scripts. A GitHub URL can be scanned, but it has no local checkout against which LXC-BRM can safely run the configured shell.

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
- Repositories and their build history persist across app restarts (stored locally under `~/Library/Application Support/LXC-BRM/`).

## Appearance

The app follows your Mac's system light/dark mode automatically. The Preferences surface also exposes theme, console, repository, execution, notification, and layout settings. Any setting still marked open in the [master worklog](../worklog/todo-2026-08-16.md) remains subject to verification.
