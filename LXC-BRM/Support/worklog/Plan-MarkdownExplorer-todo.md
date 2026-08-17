# Plan — Markdown Explorer & Viewer ("Docs" tab)

A sixth tab beside Build, Logs, History, Overview, and Settings: browse every `.md` file in the
open repository on the left, read it rendered on the right — the way GitHub renders it.

This repository alone has **67 markdown files** (READMEs, plans, worklogs, the Support handbook,
architecture notes). Today the only way to read any of them is to leave the app.

## How Markdown gets rendered — the decision

"Render it the way GitHub shows it" has four possible routes on macOS. The project constraint is
**no third-party packages** (`Foundation` / `SwiftUI` / `AppKit` only), which rules two of them out.

| Route | Verdict |
| --- | --- |
| `Text(LocalizedStringKey)` auto-markdown | **No.** Inline emphasis only. No headings, lists, code blocks, or tables. Not a document renderer. |
| `AttributedString(markdown:)` alone | **Partly.** Foundation parses inline runs — bold, italic, links, inline code, strikethrough — correctly and is the standard Apple API for it. But `.inlineOnlyPreservingWhitespace` is what actually works reliably; full-document mode collapses block structure, so headings, lists, fences, and tables all come out as flat paragraphs. |
| WKWebView + Markdown→HTML + GitHub CSS | **No.** Closest to GitHub visually, but there is no bundled Markdown→HTML converter in the SDK, so it needs a third-party parser — the one thing this project rules out. It also renders arbitrary embedded HTML and scripts from files on disk, ignores the app's own theme, and breaks native text selection and accessibility. |
| **Block parser + SwiftUI views, with `AttributedString` for inline spans** | **Yes.** Chosen. |

The chosen route splits the problem the way Markdown itself is defined:

1. **Block level** — headings, paragraphs, lists, fenced code, block quotes, tables, rules,
   images. Parsed by us, line by line. This is where GitHub's look actually comes from.
2. **Inline level** — bold, italic, links, inline code, strikethrough. Handed to
   `AttributedString(markdown:options:)`, which is the standard Foundation API and already
   correct, so we do not hand-roll an inline parser.

That gives native text selection, real accessibility, automatic light/dark support, no
dependency, and a parser that is pure and unit-testable.

## What "renders like GitHub" means here

Target the GitHub Flavored Markdown subset that actually appears in this repository's files:

| Element | Rendering |
| --- | --- |
| `#` … `######` | Six heading levels, descending size and weight; H1/H2 get a hairline rule under them, as GitHub does |
| Paragraphs | Wrapped body text, selectable |
| `**bold**` `_italic_` `~~strike~~` | Via `AttributedString` inline parsing |
| `` `inline code` `` | Monospaced, tinted background capsule |
| ```` ```lang ```` fences | Monospaced block, filled background, horizontal scroll rather than wrapping, language label |
| Indented code blocks | Same treatment as fenced |
| `-` `*` `+` lists | Bulleted, nesting preserved by indent depth |
| `1.` lists | Numbered, correct start value, nesting preserved |
| `- [ ]` / `- [x]` | Task list checkboxes, non-interactive |
| `>` quotes | Left accent bar, secondary text colour, nestable |
| Tables | Real grid with header row, per-column alignment from `:---:`, horizontal scroll |
| `---` | Horizontal rule |
| `[text](url)` | Tappable link; opens in the default browser |
| `![alt](path)` | Local images resolved relative to the file and shown; remote images show a placeholder rather than fetching |
| HTML blocks | Shown verbatim as escaped text — never executed |

## Non-Goals

- No editing. This is a reader.
- No Markdown→HTML, no `WKWebView`, no JavaScript.
- No remote image or content fetching from a document — a repository file must not be able to
  make the app phone home.
- No syntax highlighting inside code fences in this pass; monospaced with a language label first.
- No `.md` rendering for files outside the open repository.
- No third-party package.

## Work Plan

### 01. File discovery

- [ ] Walk the open repository for `.md` and `.markdown` files.
- [ ] Reuse the skip rules already proven in `DeepScriptSearch` — `.git`, `node_modules`, `Pods`, `DerivedData*`, `*.build`, and friends.
- [ ] Run the walk off the main thread; a large repository must not freeze the tab.
- [ ] Build a real tree — folders with their files nested — not a flat list, because 67 files flat is unusable.
- [ ] Sort folders before files, each alphabetically, so the order is stable between scans.
- [ ] Surface the count, and an empty state when a repository has no markdown at all.
- [ ] Refresh on demand, and when the repository changes.

### 02. Block parser

- [ ] Define a `MarkdownBlock` value covering every element in the table above.
- [ ] Parse line by line into blocks; keep it pure — a `String` in, `[MarkdownBlock]` out, no I/O.
- [ ] Fenced code: capture the language, and do not parse anything inside the fence.
- [ ] Handle an unterminated fence at end of file without dropping the content.
- [ ] Lists: track indent depth for nesting, ordered start values, and task-list markers.
- [ ] Tables: parse the delimiter row for per-column alignment, tolerate ragged rows.
- [ ] Block quotes: strip one `>` level and recurse so nested quotes work.
- [ ] Treat a line of `---` as a rule, but as a heading underline when it follows a paragraph, and as front-matter delimiters at the very top of a file.
- [ ] Skip YAML front matter rather than rendering it as a table.
- [ ] Never crash or hang on pathological input — unclosed fences, 10,000-line files, mixed tabs and spaces.

### 03. Inline rendering

- [ ] Convert inline spans with `AttributedString(markdown:options:)` using `.inlineOnlyPreservingWhitespace`.
- [ ] Fall back to plain text when a line fails to parse, rather than showing nothing.
- [ ] Keep inline code visually distinct from surrounding text.
- [ ] Make links open in the default browser, and only `http`, `https`, and `file` schemes.
- [ ] Resolve relative links against the document's own folder.

### 04. Viewer

- [ ] Render blocks in a scroll view with GitHub-like vertical rhythm.
- [ ] Headings: six sizes, with a rule under H1 and H2.
- [ ] Code blocks: monospaced, filled background, horizontal scroll, language label, copy button.
- [ ] Tables: aligned grid, header emphasis, horizontal scroll so a wide table cannot break the layout.
- [ ] Quotes, rules, task boxes, and nested lists all visually distinct.
- [ ] Local images resolved relative to the file; missing or remote images show a labelled placeholder.
- [ ] Keep the whole document selectable and copyable.
- [ ] Respect the app's text-size and density preferences.
- [ ] Work in light and dark.

### 05. Explorer and tab integration

- [ ] Add the tab to `RepositoryDetailView.DetailTab` and the picker.
- [ ] Two-pane layout: file tree left, rendered document right, with a draggable divider.
- [ ] Expandable folders; remember which are open while the repository stays selected.
- [ ] Show the selected file's name and path above the document.
- [ ] Filter box that matches on file name and folder.
- [ ] Actions on the document: Reveal in Finder, Copy Path, Open in default editor.
- [ ] Empty states for no markdown found, nothing selected, and a file that has since disappeared.
- [ ] Handle a file deleted or changed on disk between selection and read.

### 06. Tests

- [ ] Headings at all six levels, including `#hash` with no space, which is not a heading.
- [ ] Fenced code with and without a language, and an unterminated fence.
- [ ] Nested bullets, ordered lists with a non-1 start, and task list markers.
- [ ] Tables with each alignment, and a ragged row.
- [ ] Block quotes, including nested.
- [ ] Front matter is skipped, not rendered.
- [ ] `---` disambiguated between rule, setext heading, and front matter.
- [ ] Inline spans survive the round trip; a malformed span degrades to plain text.
- [ ] File discovery skips the noise directories and builds the expected tree.
- [ ] A large synthetic document parses well inside a sensible time budget.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| 01 — File discovery | 0 / 7 | Open |
| 02 — Block parser | 0 / 10 | Open |
| 03 — Inline rendering | 0 / 5 | Open |
| 04 — Viewer | 0 / 9 | Open |
| 05 — Explorer and tab | 0 / 8 | Open |
| 06 — Tests | 0 / 10 | Open |
| **Total** | **0 / 49** | **Open** |
