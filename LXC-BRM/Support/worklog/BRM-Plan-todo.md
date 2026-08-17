# BRM Plan — master index

The one place to see everything. Every other plan file is linked from here; none of them
duplicate each other's work, and each states its own boundary.

**How to use this file:** find the area you are working on, open its plan, work there. Update the
counts here when a plan's tracking table changes. Do not add task detail to this file — it is an
index, not a checklist.

## The window, by region

The app is four regions. Each owns its own plan, so a change has exactly one home.

```text
┌─────────────┬──────────────────────────────┬──────────────┐
│             │                              │              │
│ Left        │  Main panel                  │ Detail View  │
│ sidebar     │  (header + tabs + content)   │ panel        │
│             │                              │ (right)      │
├─────────────┴──────────────────────────────┴──────────────┤
│ Status bar                                                 │
└────────────────────────────────────────────────────────────┘
```

| Region | Plan | Progress |
| --- | --- | --- |
| Left sidebar — repositories, recents, open, preferences button | [Plan-LeftSidebar-todo.md](Plan-LeftSidebar-todo.md) | 25 / 27 |
| Main panel — three bands, six tabs | [Plan-MainPanel-todo.md](Plan-MainPanel-todo.md) *(index)* | see below |
| ├ Header (top) | [Plan-MainPanel-Header-todo.md](Plan-MainPanel-Header-todo.md) | 6 / 13 |
| ├ Toolbar (tab picker) | [Plan-MainPanel-Toolbar-todo.md](Plan-MainPanel-Toolbar-todo.md) | 5 / 11 |
| └ Container (work area) | [Plan-MainPanel-Container-todo.md](Plan-MainPanel-Container-todo.md) | 4 / 7 |
| Detail View panel — the right inspector | [Plan-DetailViewPanel-todo.md](Plan-DetailViewPanel-todo.md) | 12 / 18 |
| Status bar — the bottom strip | [Plan-StatusBar-todo.md](Plan-StatusBar-todo.md) | 9 / 16 |

## The six tabs, inside the container

| Tab | Plan | Progress |
| --- | --- | --- |
| Build | [Plan-Tab-Build-todo.md](Plan-Tab-Build-todo.md) | 146 / 146 ✅ |
| Logs | [Plan-Tab-Logs-todo.md](Plan-Tab-Logs-todo.md) | 3 / 5 |
| History | [Plan-Tab-History-todo.md](Plan-Tab-History-todo.md) | 4 / 7 |
| Overview | [Plan-Tab-Overview-todo.md](Plan-Tab-Overview-todo.md) | 4 / 7 |
| Docs | [Plan-MarkdownExplorer-todo.md](Plan-MarkdownExplorer-todo.md) | 75 / 85 |
| Settings *(per-repository)* | [Plan-Tab-Settings-todo.md](Plan-Tab-Settings-todo.md) | 3 / 6 |

## Features

| Feature | Plan | Progress |
| --- | --- | --- |
| Preferences window — all seven tabs and their wiring | [Plan-PreferenceScreen-todo.md](Plan-PreferenceScreen-todo.md) | see file |
| Update checking — GitHub Releases, stable and beta channels | [Plan-Updates-todo.md](Plan-Updates-todo.md) | 22 / 23 |
| Localization — English and Hindi | [Plan-Localization-todo.md](Plan-Localization-todo.md) | 19 / 19 ✅ |
| Window layout — resizing, View menu, panel visibility | [Plan-WindowLayout-todo.md](Plan-WindowLayout-todo.md) | 90 / 90 ✅ |

## Engineering

| Area | Plan | Progress |
| --- | --- | --- |
| Code refactoring and reusability | [Plan-CodeRefactoring-Reusability-todo.md](Plan-CodeRefactoring-Reusability-todo.md) | 23 / 61 |
| Xcode project & IDE — target membership, build settings, schemes | [Plan-XcodeProject-todo.md](Plan-XcodeProject-todo.md) | 3 / 13 |
| Architecture diagrams and context visuals | [Plan-ContextArchitectureVisuals-todo.md](Plan-ContextArchitectureVisuals-todo.md) | 25 / 25 ✅ |
| The original dated master checklist | [todo-2026-08-16.md](todo-2026-08-16.md) | 75 / 78 |

## Where a new task goes

| If it is about… | Put it in |
| --- | --- |
| A repository row, the recents list, the open or preferences **button** | Left sidebar |
| Anything **inside** the Preferences window | Preferences screen |
| The repo name, badge, paths, or Reveal/Terminal/Copy | Main panel → Header |
| The tab picker or its divider | Main panel → Toolbar |
| The work area's surface, padding, or card style | Main panel → Container |
| What a specific tab shows or does | That tab's own plan |
| A file not compiling, target membership, build settings | Xcode project |
| The right inspector's cards, width, or visibility | Detail View panel |
| The bottom strip | Status bar |
| Rendering or browsing markdown | Markdown explorer |
| Moving code without changing behaviour | Code refactoring |

If a task genuinely spans two regions, it belongs to the one that owns the **visible surface**,
and the other plan links to it rather than restating it.

## Retired files

| File | Superseded by |
| --- | --- |
| `BuildScreen-plan-todo.md` | [Plan-MainPanel-todo.md](Plan-MainPanel-todo.md) |
| `BuildScreen-plan-todo_OLD.md` | [Plan-MainPanel-todo.md](Plan-MainPanel-todo.md) |
| `Plan-Sidebar-todo.md` | [Plan-LeftSidebar-todo.md](Plan-LeftSidebar-todo.md) — renamed, because the app has a right sidebar too |
| The Build sections formerly inside `Plan-MainPanel-todo.md` | [Plan-Tab-Build-todo.md](Plan-Tab-Build-todo.md) — Main Panel is now an index only |

## Conventions

1. `[x]` only when the code exists, builds, and the behaviour was checked. Not for "planned".
2. When something cannot be finished, it stays `[ ]` with a note saying **why** — an unchecked
   box with a reason is worth more than a checked box that is not true.
3. Every plan carries a Tracking table with its own counts.
4. The narrative of what actually happened goes in `worklog-YYYY-MM-DD.md`, not in the plans.
