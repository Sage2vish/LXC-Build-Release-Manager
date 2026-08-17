# BRM Plan — master index

**Start here.** This is the one place that sees everything. Every plan in this folder is linked
from a table below; none of them duplicate each other's work, and each states its own boundary.

**How to use this file:** find the area you are working on in a table, open its plan through the
link, and work there. Update the count here when that plan's tracking table changes. Do not add
task detail to this file — it is an index and a map, not a checklist.

Counts are read from each plan's own tracking table. `✅` means the plan is closed out.

## The window, by region

The app is four regions. Each owns its own plan, so a change has exactly one home.

```text
┌─────────────┬──────────────────────────────┬──────────────┐
│             │                              │              │
│ Left        │  Main panel                  │ Detail View  │
│ sidebar     │  (header + toolbar + tabs)   │ panel        │
│             │                              │ (right)      │
├─────────────┴──────────────────────────────┴──────────────┤
│ Status bar                                                 │
└────────────────────────────────────────────────────────────┘
```

| Region | Plan | What it owns | Progress |
| --- | --- | --- | --- |
| **Whole window** | [Plan-AppShellUI-todo.md](Plan-AppShellUI-todo.md) | Background image, material and glass language, theme and accent across regions | 0 / 15 |
| **Left sidebar** | [Plan-LeftSidebar-todo.md](Plan-LeftSidebar-todo.md) | Repositories, recents, adding and removing, the Open and Preferences buttons | 33 / 35 |
| **Main panel** | [Plan-MainPanel-todo.md](Plan-MainPanel-todo.md) *(index)* | Three bands and six tabs — broken out below | see below |
| **Detail View panel** | [Plan-DetailViewPanel-todo.md](Plan-DetailViewPanel-todo.md) | The right inspector: selected script, parameters, status, history, quick actions | 12 / 18 |
| **Status bar** | [Plan-StatusBar-todo.md](Plan-StatusBar-todo.md) | The bottom strip: repository, branch, platform, auto-detect chips | 9 / 16 |

## Inside the main panel

The centre column is three stacked bands. [Plan-MainPanel-todo.md](Plan-MainPanel-todo.md) is an
index only — every task lives in one of these.

| Band | Plan | What it owns | Progress |
| --- | --- | --- | --- |
| **Header** (top) | [Plan-MainPanel-Header-todo.md](Plan-MainPanel-Header-todo.md) | Repository name, badge, path lines, Reveal / Terminal / Copy | 8 / 13 |
| **Toolbar** (middle) | [Plan-MainPanel-Toolbar-todo.md](Plan-MainPanel-Toolbar-todo.md) | The six-tab picker and the rule beneath it | 7 / 11 |
| **Container** (work area) | [Plan-MainPanel-Container-todo.md](Plan-MainPanel-Container-todo.md) | The surface, padding, scrolling, shared card treatment | 5 / 8 |

## The six tabs, inside the container

| Tab | Plan | What it owns | Progress |
| --- | --- | --- | --- |
| **Build** | [Plan-Tab-Build-todo.md](Plan-Tab-Build-todo.md) | Script discovery, the scripts table, parameters, execution, live output | 161 / 163 |
| **Logs** | [Plan-Tab-Logs-todo.md](Plan-Tab-Logs-todo.md) | Saved log files, filters, search, export | 9 / 11 |
| **History** | [Plan-Tab-History-todo.md](Plan-Tab-History-todo.md) | Every recorded run for the repository | 4 / 7 |
| **Overview** | [Plan-Tab-Overview-todo.md](Plan-Tab-Overview-todo.md) | Repository summary and build statistics | 4 / 7 |
| **Docs** | [Plan-MarkdownExplorer-todo.md](Plan-MarkdownExplorer-todo.md) | Markdown discovery, rendering, Preview/Source editing | 75 / 86 |
| **Settings** | [Plan-Tab-Settings-todo.md](Plan-Tab-Settings-todo.md) | Per-repository settings — *not* the app-wide Preferences window | 3 / 6 |

## Features

| Feature | Plan | What it owns | Progress |
| --- | --- | --- | --- |
| **Preferences window** | [Plan-PreferenceScreen-todo.md](Plan-PreferenceScreen-todo.md) | All seven tabs, every field, the draft/Save/Cancel flow, and the wiring audit | 55 X · 6 D · 30 P of 91 |
| **Update checking** | [Plan-Updates-todo.md](Plan-Updates-todo.md) | GitHub Releases feed, version comparison, stable and beta channels | 22 / 23 |
| **Localization** | [Plan-Localization-todo.md](Plan-Localization-todo.md) | English and Hindi, the string catalogue, language switching | 19 / 19 ✅ |
| **Window layout** | [Plan-WindowLayout-todo.md](Plan-WindowLayout-todo.md) | Resizing, the View menu, panel visibility and persistence | 90 / 90 ✅ |

## Engineering, quality, and release

| Area | Plan | What it owns | Progress |
| --- | --- | --- | --- |
| **Code refactoring** | [Plan-CodeRefactoring-Reusability-todo.md](Plan-CodeRefactoring-Reusability-todo.md) | Feature extraction, dependency seams, reuse — behaviour preserving | 31 / 69 |
| **Xcode project & IDE** | [Plan-XcodeProject-todo.md](Plan-XcodeProject-todo.md) | Target membership, build settings, schemes, project-file hygiene | 5 / 15 |
| **Quality & verification** | [Plan-QualityVerification-todo.md](Plan-QualityVerification-todo.md) | Non-functional targets, test suite state, GUI coverage, standing caveats, evidence ledger | 18 / 25 |
| **Release & packaging** | [Plan-ReleasePackaging-todo.md](Plan-ReleasePackaging-todo.md) | The release script, staging, the `.dmg`, tags, signing and distribution | 9 / 16 |
| **Context & architecture visuals** | [Plan-ContextArchitectureVisuals-todo.md](Plan-ContextArchitectureVisuals-todo.md) | The SVG diagram set and the documentation wiring around it | 25 / 25 ✅ |

## Requirements coverage

Where each section of [`context/requirements.md`](../context/requirements.md) is actually
tracked, so a requirement can always be traced to the plan that owns it.

| Requirement | Owning plan | State |
| --- | --- | --- |
| §1 Repository input and detection | [Left sidebar](Plan-LeftSidebar-todo.md) (input) · [Build tab](Plan-Tab-Build-todo.md) (scanning) | Shipped |
| §2 Build execution and management | [Build tab](Plan-Tab-Build-todo.md) | Shipped |
| §3 Log storage and retrieval | [Logs tab](Plan-Tab-Logs-todo.md) | Shipped |
| §4 Project and build overview | [Overview tab](Plan-Tab-Overview-todo.md) · [History tab](Plan-Tab-History-todo.md) | Shipped, with one deviation |
| §5 Multi-repository support | [Left sidebar](Plan-LeftSidebar-todo.md) | Shipped |
| §6 Non-functional targets | [Quality & verification](Plan-QualityVerification-todo.md) | Measured and met |
| §7 Packaging and deliverables | [Release & packaging](Plan-ReleasePackaging-todo.md) | Artifact staged; nothing published yet |
| Workspace foundation | [Xcode project](Plan-XcodeProject-todo.md) · [`context/architecture.md`](../context/architecture.md) | Shipped |

The deviation under §4 — "Total Builds Run" being all-time rather than per-session — and every
other standing caveat is listed in
[Plan-QualityVerification-todo.md](Plan-QualityVerification-todo.md) section 05.

## Where a new task goes

| If it is about… | Put it in |
| --- | --- |
| A repository row, the recents list, adding/removing a repository, the open or preferences **button** | [Left sidebar](Plan-LeftSidebar-todo.md) |
| Anything **inside** the Preferences window | [Preferences screen](Plan-PreferenceScreen-todo.md) |
| The repo name, badge, paths, or Reveal/Terminal/Copy | [Main panel → Header](Plan-MainPanel-Header-todo.md) |
| The tab picker or its divider | [Main panel → Toolbar](Plan-MainPanel-Toolbar-todo.md) |
| The work area's surface, padding, or card style | [Main panel → Container](Plan-MainPanel-Container-todo.md) |
| What a specific tab shows or does | That tab's own plan |
| A file not compiling, target membership, build settings | [Xcode project](Plan-XcodeProject-todo.md) |
| The right inspector's cards, width, or visibility | [Detail View panel](Plan-DetailViewPanel-todo.md) |
| The bottom strip | [Status bar](Plan-StatusBar-todo.md) |
| Rendering or browsing markdown | [Docs / Markdown explorer](Plan-MarkdownExplorer-todo.md) |
| The window background, glass/material language, or theme across regions | [App shell UI](Plan-AppShellUI-todo.md) |
| Moving code without changing behaviour | [Code refactoring](Plan-CodeRefactoring-Reusability-todo.md) |
| A measurement, a test run, or "has this actually been clicked?" | [Quality & verification](Plan-QualityVerification-todo.md) |
| The `.dmg`, the tag, signing, or publishing | [Release & packaging](Plan-ReleasePackaging-todo.md) |
| A diagram, or the context documents around the code | [Context & architecture visuals](Plan-ContextArchitectureVisuals-todo.md) |

If a task genuinely spans two regions, it belongs to the one that owns the **visible surface**,
and the other plan links to it rather than restating it.

## Every plan file, at a glance

| File | Area |
| --- | --- |
| [Plan-AppShellUI-todo.md](Plan-AppShellUI-todo.md) | Whole-window visual identity |
| [Plan-CodeRefactoring-Reusability-todo.md](Plan-CodeRefactoring-Reusability-todo.md) | Engineering |
| [Plan-ContextArchitectureVisuals-todo.md](Plan-ContextArchitectureVisuals-todo.md) | Documentation |
| [Plan-DetailViewPanel-todo.md](Plan-DetailViewPanel-todo.md) | Region — right panel |
| [Plan-LeftSidebar-todo.md](Plan-LeftSidebar-todo.md) | Region — left sidebar |
| [Plan-Localization-todo.md](Plan-Localization-todo.md) | Feature |
| [Plan-MainPanel-todo.md](Plan-MainPanel-todo.md) | Region — centre *(index)* |
| [Plan-MainPanel-Header-todo.md](Plan-MainPanel-Header-todo.md) | Centre — band 1 |
| [Plan-MainPanel-Toolbar-todo.md](Plan-MainPanel-Toolbar-todo.md) | Centre — band 2 |
| [Plan-MainPanel-Container-todo.md](Plan-MainPanel-Container-todo.md) | Centre — band 3 |
| [Plan-MarkdownExplorer-todo.md](Plan-MarkdownExplorer-todo.md) | Tab — Docs |
| [Plan-PreferenceScreen-todo.md](Plan-PreferenceScreen-todo.md) | Feature |
| [Plan-QualityVerification-todo.md](Plan-QualityVerification-todo.md) | Quality |
| [Plan-ReleasePackaging-todo.md](Plan-ReleasePackaging-todo.md) | Release |
| [Plan-StatusBar-todo.md](Plan-StatusBar-todo.md) | Region — bottom strip |
| [Plan-Tab-Build-todo.md](Plan-Tab-Build-todo.md) | Tab — Build |
| [Plan-Tab-History-todo.md](Plan-Tab-History-todo.md) | Tab — History |
| [Plan-Tab-Logs-todo.md](Plan-Tab-Logs-todo.md) | Tab — Logs |
| [Plan-Tab-Overview-todo.md](Plan-Tab-Overview-todo.md) | Tab — Overview |
| [Plan-Tab-Settings-todo.md](Plan-Tab-Settings-todo.md) | Tab — Settings |
| [Plan-Updates-todo.md](Plan-Updates-todo.md) | Feature |
| [Plan-WindowLayout-todo.md](Plan-WindowLayout-todo.md) | Feature |
| [Plan-XcodeProject-todo.md](Plan-XcodeProject-todo.md) | Engineering |

## Retired files

Nothing here still exists in the folder. The table records where the content went, so a link from
an old commit or note can still be followed.

| File | Where its content lives now |
| --- | --- |
| `todo-2026-08-16.md` — the dated master checklist | Settings checklist and the 73-field audit → [Preferences](Plan-PreferenceScreen-todo.md) · requirement phases §1/§5 → [Left sidebar](Plan-LeftSidebar-todo.md) · §2 → [Build tab](Plan-Tab-Build-todo.md) · §3 → [Logs tab](Plan-Tab-Logs-todo.md) · §6 and the caveats → [Quality & verification](Plan-QualityVerification-todo.md) · §7 → [Release & packaging](Plan-ReleasePackaging-todo.md) · code health → [Code refactoring](Plan-CodeRefactoring-Reusability-todo.md) · decision overrides → [`context/decisions/`](../context/decisions/) |
| `worklog-2026-08-16.md` — the dated narrative | Verification evidence and measurements → [Quality & verification](Plan-QualityVerification-todo.md) · preferences audit → [Preferences](Plan-PreferenceScreen-todo.md) · layout story → [Window layout](Plan-WindowLayout-todo.md) · refactor baseline → [Code refactoring](Plan-CodeRefactoring-Reusability-todo.md) · release staging → [Release & packaging](Plan-ReleasePackaging-todo.md) |
| `BuildScreen-plan-todo.md` | [Plan-MainPanel-todo.md](Plan-MainPanel-todo.md) → [Plan-Tab-Build-todo.md](Plan-Tab-Build-todo.md) |
| `BuildScreen-plan-todo_OLD.md` | [Plan-MainPanel-todo.md](Plan-MainPanel-todo.md) |
| `Plan-Sidebar-todo.md` | [Plan-LeftSidebar-todo.md](Plan-LeftSidebar-todo.md) — renamed, because the app has a right sidebar too |
| The Build sections formerly inside `Plan-MainPanel-todo.md` | [Plan-Tab-Build-todo.md](Plan-Tab-Build-todo.md) — Main Panel is now an index only |

## Conventions

1. `[x]` only when the code exists, builds, and the behaviour was checked. Not for "planned".
2. When something cannot be finished, it stays `[ ]` with a note saying **why** — an unchecked
   box with a reason is worth more than a checked box that is not true.
3. Every plan carries a Tracking table with its own counts, and this index mirrors them.
4. The narrative of what actually happened lives in the plan that owns the work — usually an
   "Already shipped" list or a verification section. There is no dated worklog file; the
   cross-cutting evidence ledger is in
   [Plan-QualityVerification-todo.md](Plan-QualityVerification-todo.md).
5. Every file in this folder is named `Plan-<Area>-todo.md` and is linked from this index. A new
   plan is not real until it appears in a table above.
6. When a plan changes a rule, an architecture boundary, or a product decision, update
   [`context/`](../context/README.md) in the same change.
