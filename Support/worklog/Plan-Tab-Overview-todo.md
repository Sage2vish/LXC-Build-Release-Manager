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

- [ ] Statistics are all-time with no date range.
- [ ] Wrap the stat cards in the container's shared card treatment.
      *(Shape owned by [`Plan-MainPanel-Container-todo.md`](Plan-MainPanel-Container-todo.md).)*
- [ ] "Total Builds Run" is all-time, while the requirements describe a per-session counter — a deliberate deviation worth confirming.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 4 / 4 | Done |
| 01 — Open items | 0 / 3 | Open |
