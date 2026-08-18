# Plan — History tab

> **Owns:** the History tab: every run recorded for the selected repository.
>
> One of six tabs inside the [main panel's container](Plan-MainPanel-Container-todo.md).
> Siblings: [Build](Plan-Tab-Build-todo.md) · [Logs](Plan-Tab-Logs-todo.md) ·
> [History](Plan-Tab-History-todo.md) · [Overview](Plan-Tab-Overview-todo.md) ·
> [Docs](Plan-MarkdownExplorer-todo.md) · [Settings](Plan-Tab-Settings-todo.md)

Every run recorded for this repository.

## Work plan

## Already shipped

- [x] One row per run: status icon, script label, timestamp, duration.
- [x] Clicking a row opens that run's log.
- [x] Extracted into a standalone RepositoryHistoryView driven by records alone.
- [x] Empty state when nothing has run.

## 01. Open items

- [ ] No way to clear or prune history from this tab.
- [ ] No filtering by status or script.
- [ ] Adopt the shared card treatment once the container defines it — the tab applies it, the shape is owned by [`Plan-MainPanel-Container-todo.md`](Plan-MainPanel-Container-todo.md).

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 4 / 4 | Done |
| 01 — Open items | 0 / 3 | Open |
