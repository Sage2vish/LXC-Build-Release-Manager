# Plan — Main panel: Toolbar (middle)

> The middle band of the [main panel](Plan-MainPanel-todo.md). Siblings:
> [Header](Plan-MainPanel-Header-todo.md) · [Container](Plan-MainPanel-Container-todo.md)

The tab picker, and the rule that separates it from the content below. It decides which of the
six tabs the container shows.

## What it contains

| Element | Detail |
| --- | --- |
| Tab picker | Build · Logs · History · Overview · Docs · Settings, segmented, one at a time |
| Divider | A single rule below the picker, separating it from the container |

## Already shipped

- [x] Segmented picker across all six tabs, mutually exclusive by construction.
- [x] Opening tab follows the "Default tab on launch" preference.
- [x] Switches to History after a build when the preference says so.
- [x] A single divider below the picker — one rule, not a border box.
- [x] Docs bypasses the shared content ScrollView, since it manages its own panes.

## 01. Glass effect

- [ ] Give the toolbar band the same translucent material as the header, so the two read as one
      chrome region above the content.
- [ ] Respect the **Reduce transparency** preference.
- [ ] Keep the selected segment clearly readable over the material.
- [ ] Verify in light and dark, and at the minimum panel width where six segments are tightest.

## 02. Open items

- [ ] Six segments is close to the practical limit for a segmented control at narrow widths.
      Decide what happens when a seventh tab is added.
- [ ] Tab names are localizable, but the picker's width is not — check Hindi does not overflow.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 5 / 5 | Done |
| 01 — Glass effect | 0 / 4 | Open |
| 02 — Open items | 0 / 2 | Open |
| **Total** | **5 / 11** | **In progress** |
