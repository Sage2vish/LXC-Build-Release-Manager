# Plan — Logs tab

> **Owns:** the Logs tab: saved log files, filters, search, and export.
>
> One of six tabs inside the [main panel's container](Plan-MainPanel-Container-todo.md).
> Siblings: [Build](Plan-Tab-Build-todo.md) · [Logs](Plan-Tab-Logs-todo.md) ·
> [History](Plan-Tab-History-todo.md) · [Overview](Plan-Tab-Overview-todo.md) ·
> [Docs](Plan-MarkdownExplorer-todo.md) · [Settings](Plan-Tab-Settings-todo.md)

Saved build logs, opened from History or chosen directly.

## Work plan

## Already shipped

- [x] Renders a saved log with the same LogPane used for live output.
- [x] Filters, search, line numbers, wrapping and auto-scroll follow the Logs preferences.
- [x] Export a log to a chosen location.

### Log storage and retrieval (requirements §3)

- [x] Every run writes a log file to `<repository>/build/logs/` named
      `build-YYYY-MM-DD-HH-MM-SS.log`, holding the full stdout and stderr as plain text.
- [x] Both the current live output and past logs opened from History are viewable.
- [x] Monospace, terminal-style presentation — dark background, light text, per-line timestamps,
      scrollable.
- [x] In-log search highlights matches, shows a match count, and navigates next/previous.
- [x] Filters for Errors Only, Warnings Only, and Info Only.
- [x] Export the current log to a chosen location, defaulting to Downloads, as `.log`.

## 01. Open items

- [ ] Live output and saved logs still take two code paths into the same pane; consolidate them.
- [x] A saved-log picker sits above the pane: every recorded run for this repository, labelled
      by script and time — which is how someone actually looks for one — newest first, with the
      run's outcome beside it and a shortcut to the logs folder. History is now one route to a
      log rather than the only one.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 3 / 3 | Done |
| Log storage and retrieval (§3) | 6 / 6 | Done |
| 01 — Open items | 1 / 2 | Consolidation still open |
| **Total** | **10 / 11** | **In progress** |
