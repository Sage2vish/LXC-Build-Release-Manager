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

- [x] Clear this repository's history from the tab, guarded by a confirmation that says what it
      does and does not touch — log files on disk and other repositories are left alone. The
      confirmation follows the "Confirm before clearing" preference. `BuildHistoryStore.clear(for:)`
      is deliberately separate from `clearAll()`: a tab-scoped control must never reach past its
      repository.
- [x] Filter by outcome (All / Succeeded / Failed / Cancelled) and by script, with the script
      list derived from the records themselves so a run of a since-deleted script still appears.
      Filtering rules live in `HistoryFilter` and are unit-tested; a filtered list states how many
      runs it is hiding, so "nothing matches" can never be mistaken for "nothing ran".
- [x] Uses the shared `sectionCard()` rather than a `GroupBox`, so History matches the Build tab.
      *(Shape owned by [`Plan-MainPanel-Container-todo.md`](Plan-MainPanel-Container-todo.md).)*

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 4 / 4 | Done |
| 01 — Open items | 3 / 3 | Done |

