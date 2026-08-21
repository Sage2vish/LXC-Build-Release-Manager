# Plan — Main panel: Toolbar (middle)

> **Owns:** the middle band of the centre column: the six-tab picker and the rule beneath it.
>
> The middle band of the [main panel](Plan-MainPanel-todo.md). Siblings:
> [Header](Plan-MainPanel-Header-todo.md) · [Container](Plan-MainPanel-Container-todo.md)

The tab picker, and the rule that separates it from the content below. It decides which of the
six tabs the container shows.

## What it contains

| Element | Detail |
| --- | --- |
| Tab picker | Build · Logs · History · Overview · Docs · Settings, segmented, one at a time |
| Divider | A single rule below the picker, separating it from the container |

## Work plan

## Already shipped

- [x] Segmented picker across all six tabs, mutually exclusive by construction.
- [x] Opening tab follows the "Default tab on launch" preference.
- [x] Switches to History after a build when the preference says so.
- [x] A single divider below the picker — one rule, not a border box.
- [x] Docs bypasses the shared content ScrollView, since it manages its own panes.

## 01. Glass effect

- [x] Give the toolbar band the same translucent material as the header — they are now one band.
- [x] Respect the **Reduce transparency** preference.
- [x] The band now has a bottom edge. There was no rule under the tab picker at all, so the
      chrome bled straight into the work area and the tabs looked like they were floating on the
      content rather than sitting in a band above it.
- [ ] Keep the selected segment clearly readable over the material.
- [ ] Verify in light and dark, and at the minimum panel width where six segments are tightest.

## 03. What the tabs are called, and in what order

- [x] **Build is now Scripts.** The tab lists a repository's scripts; *build* and *release* mean
      something narrower in this project and those words are kept for the work that carries them.
- [x] Order is **Overview · Scripts · Logs · History · Docs · Settings**. Overview first: it answers
      "what is this repository?", which is the question you have before running anything.
- [x] One place names them — `RepositoryDetailView.DetailTab.title`. The tab picker and the
      "default launch tab" preference both read it, so a rename cannot go half-applied.
- [x] The stored preference values are untouched, so an existing `preferences.json` still decodes;
      only what a person reads changed.
- [ ] The names are `LocalizedStringKey`s; **Scripts** and **Docs** still need catalogue entries in
      the non-English languages.

## 02. Open items

- [ ] Six segments is close to the practical limit for a segmented control at narrow widths.
      Decide what happens when a seventh tab is added.
- [ ] Tab names are localizable, but the picker's width is not — check Hindi does not overflow.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| Already shipped | 5 / 5 | Done |
| 01 — Glass effect | 2 / 4 | In progress |
| 03 — Tab names and order | 4 / 5 | Built; translations open |
| 02 — Open items | 0 / 2 | Open |
| **Total** | **11 / 16** | **In progress** |
