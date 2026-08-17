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
| Left sidebar — repositories, recents, open, preferences button | [Plan-LeftSidebar-todo.md](Plan-LeftSidebar-todo.md) | 13 / 27 |
| Main panel — header, tabs, Build/Logs/History/Overview/Docs/Settings | [Plan-MainPanel-todo.md](Plan-MainPanel-todo.md) | 146 / 155 |
| Detail View panel — the right inspector | [Plan-DetailViewPanel-todo.md](Plan-DetailViewPanel-todo.md) | 7 / 18 |
| Status bar — the bottom strip | [Plan-StatusBar-todo.md](Plan-StatusBar-todo.md) | 9 / 16 |

## Features

| Feature | Plan | Progress |
| --- | --- | --- |
| Preferences window — all seven tabs and their wiring | [Plan-PreferenceScreen-todo.md](Plan-PreferenceScreen-todo.md) | see file |
| Markdown Docs tab — explorer, viewer, HTML, Preview/Source | [Plan-MarkdownExplorer-todo.md](Plan-MarkdownExplorer-todo.md) | 46 / 77 |
| Update checking — GitHub Releases, stable and beta channels | [Plan-Updates-todo.md](Plan-Updates-todo.md) | 22 / 23 |
| Localization — English and Hindi | [Plan-Localization-todo.md](Plan-Localization-todo.md) | 19 / 19 ✅ |
| Window layout — resizing, View menu, panel visibility | [Plan-WindowLayout-todo.md](Plan-WindowLayout-todo.md) | 90 / 90 ✅ |

## Engineering

| Area | Plan | Progress |
| --- | --- | --- |
| Code refactoring and reusability | [Plan-CodeRefactoring-Reusability-todo.md](Plan-CodeRefactoring-Reusability-todo.md) | 23 / 61 |
| Architecture diagrams and context visuals | [Plan-ContextArchitectureVisuals-todo.md](Plan-ContextArchitectureVisuals-todo.md) | 25 / 25 ✅ |
| The original dated master checklist | [todo-2026-08-16.md](todo-2026-08-16.md) | 75 / 78 |

## Where a new task goes

| If it is about… | Put it in |
| --- | --- |
| A repository row, the recents list, the open or preferences **button** | Left sidebar |
| Anything **inside** the Preferences window | Preferences screen |
| The header, the tabs, or any tab's content | Main panel |
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

## Conventions

1. `[x]` only when the code exists, builds, and the behaviour was checked. Not for "planned".
2. When something cannot be finished, it stays `[ ]` with a note saying **why** — an unchecked
   box with a reason is worth more than a checked box that is not true.
3. Every plan carries a Tracking table with its own counts.
4. The narrative of what actually happened goes in `worklog-YYYY-MM-DD.md`, not in the plans.
