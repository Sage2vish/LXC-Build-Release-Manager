# Plan — Overview tab

> **Owns:** the Overview tab: repository summary and build statistics.
>
> One of six tabs inside the [main panel's container](Plan-MainPanel-Container-todo.md).
> Siblings: [Build](Plan-Tab-Build-todo.md) · [Logs](Plan-Tab-Logs-todo.md) ·
> [History](Plan-Tab-History-todo.md) · [Overview](Plan-Tab-Overview-todo.md) ·
> [Docs](Plan-MarkdownExplorer-todo.md) · [Settings](Plan-Tab-Settings-todo.md)

Repository summary and build statistics.

## Work plan

## Already shipped

- [x] Name, path, connection badge, total builds.
- [x] Stat cards: total builds, success rate, average duration.
- [x] Most recently run and last failed build.
- [x] Extracted into a standalone RepositoryOverviewView driven by RepositoryStats.

## 01. Open items

- [x] A date range sits beside the statistics: All time (default), 7, 30 or 90 days. The card
      states which window is on screen and how many runs it covers, because a success rate over
      a week and one over all time are different claims that the numbers alone do not
      distinguish. `StatsRange` and `RepositoryStats.make(from:)` are pure and tested, and the
      store now uses the same arithmetic so ranged and all-time figures cannot disagree.
- [x] Both sections use the shared `sectionCard()`, so Overview matches the Build tab.
      *(Shape owned by [`Plan-MainPanel-Container-todo.md`](Plan-MainPanel-Container-todo.md).)*
- [ ] "Total Builds Run" is all-time, while the requirements describe a per-session counter — a deliberate deviation worth confirming.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 4 / 4 | Done |
| 01 — Open items | 2 / 3 | Deviation still open for your call |
