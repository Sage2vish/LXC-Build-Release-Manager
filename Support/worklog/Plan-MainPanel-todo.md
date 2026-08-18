# Plan — Main Panel (centre)

> **Owns:** nothing directly — it is the index for the centre column's three bands and six tabs, each of which has its own plan.
>
> The centre column of the window. The other three regions have their own plans:
> [left sidebar](Plan-LeftSidebar-todo.md) · [right Detail View panel](Plan-DetailViewPanel-todo.md) ·
> [bottom status bar](Plan-StatusBar-todo.md).
>
> **This file is an index.** It holds no tasks of its own — every task lives in one of the plans
> below. Supersedes the former `BuildScreen-plan-todo.md` and `BuildScreen-plan-todo_OLD.md`.

## The three bands

The main panel is three stacked regions, each with its own plan.

```text
┌──────────────────────────────────────────────┐
│ Header      repo name · badge · paths · actions │
├──────────────────────────────────────────────┤
│ Toolbar     Build Logs History Overview Docs Settings │
├──────────────────────────────────────────────┤
│                                              │
│ Container   whatever the toolbar selected    │
│                                              │
└──────────────────────────────────────────────┘
```

| Band | What it owns | Plan |
| --- | --- | --- |
| **Header** (top) | Repository identity, path lines, the three repo-wide actions | [Plan-MainPanel-Header-todo.md](Plan-MainPanel-Header-todo.md) |
| **Toolbar** (middle) | The six-tab picker and the rule beneath it | [Plan-MainPanel-Toolbar-todo.md](Plan-MainPanel-Toolbar-todo.md) |
| **Container** (work area) | The surface, spacing, scrolling, and shared card treatment | [Plan-MainPanel-Container-todo.md](Plan-MainPanel-Container-todo.md) |

## The six tabs

Everything a tab *does* belongs to its own plan, not to the container.

| Tab | Plan |
| --- | --- |
| Build | [Plan-Tab-Build-todo.md](Plan-Tab-Build-todo.md) |
| Logs | [Plan-Tab-Logs-todo.md](Plan-Tab-Logs-todo.md) |
| History | [Plan-Tab-History-todo.md](Plan-Tab-History-todo.md) |
| Overview | [Plan-Tab-Overview-todo.md](Plan-Tab-Overview-todo.md) |
| Docs | [Plan-MarkdownExplorer-todo.md](Plan-MarkdownExplorer-todo.md) |
| Settings | [Plan-Tab-Settings-todo.md](Plan-Tab-Settings-todo.md) |

## Where a task about the centre column goes

| If it is about… | Put it in |
| --- | --- |
| The repository name, badge, path lines, or Reveal/Terminal/Copy | Header |
| The tab picker, its divider, or switching tabs | Toolbar |
| The work area's surface, padding, scrolling, or card style | Container |
| What a specific tab shows or does | That tab's plan |
| The app-wide Preferences **window** | [Plan-PreferenceScreen-todo.md](Plan-PreferenceScreen-todo.md) |

Note the distinction: the **Settings tab** is per-repository. The **Preferences window** is
app-wide. They are different surfaces with different plans.

## Rolled-up progress

| Plan | Progress |
| --- | --- |
| Header | 6 / 13 |
| Toolbar | 5 / 11 |
| Container | 4 / 7 |
| Build tab | 146 / 146 |
| Logs tab | 3 / 5 |
| History tab | 4 / 7 |
| Overview tab | 4 / 7 |
| Docs tab | see [Plan-MarkdownExplorer-todo.md](Plan-MarkdownExplorer-todo.md) |
| Settings tab | 3 / 6 |

## Tracking

This file holds no tasks of its own — it is an index. Progress lives in the plans
it links to, and is rolled up in [`BRM-Plan-todo.md`](BRM-Plan-todo.md).
