# Plan — Main panel: Container (work area)

> The lower, largest band of the [main panel](Plan-MainPanel-todo.md). Siblings:
> [Header](Plan-MainPanel-Header-todo.md) · [Toolbar](Plan-MainPanel-Toolbar-todo.md)

The work area. Whatever the toolbar selected is rendered here. This plan owns the **container**
— its surface, spacing, scrolling, and the shared section-card treatment — not the contents of
any individual tab.

## The six tabs

Each has its own plan. Nothing about a tab's behaviour belongs in this file.

| Tab | Plan |
| --- | --- |
| Build | [Plan-Tab-Build-todo.md](Plan-Tab-Build-todo.md) |
| Logs | [Plan-Tab-Logs-todo.md](Plan-Tab-Logs-todo.md) |
| History | [Plan-Tab-History-todo.md](Plan-Tab-History-todo.md) |
| Overview | [Plan-Tab-Overview-todo.md](Plan-Tab-Overview-todo.md) |
| Docs | [Plan-MarkdownExplorer-todo.md](Plan-MarkdownExplorer-todo.md) |
| Settings | [Plan-Tab-Settings-todo.md](Plan-Tab-Settings-todo.md) |

## Already shipped

- [x] Shared scroll view with consistent padding for the five scrolling tabs.
- [x] Docs opts out and manages its own split panes and scrolling.
- [x] One shared `SectionCard` surface — neutral grey, one border — applied to Available Build
      Scripts and Live Output so they cannot drift apart again.
- [x] Content re-keys on repository identity, so switching repositories resets tab state.

## 01. Open items

- [x] Tinted subtitle bars under both section titles, matching between Available Build Scripts and Live Output.
- [ ] Apply the shared `SectionCard` to the remaining tabs' sections, so History, Overview and
      Settings match Build rather than each inventing their own surface.
- [ ] Verify the card surface in dark mode; it has only been checked in light.
- [ ] The container's minimum width is the main contributor to the window's 1513pt floor.
      Decide what the container should drop or reflow at narrow widths.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 4 / 4 | Done |
| 01 — Open items | 1 / 4 | In progress |
| **Total** | **5 / 8** | **In progress** |
