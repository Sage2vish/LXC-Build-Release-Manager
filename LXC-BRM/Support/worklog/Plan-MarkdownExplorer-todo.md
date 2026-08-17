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

- [x] Walk the open repository for `.md` and `.markdown` files.
- [x] Reuse the skip rules already proven in `DeepScriptSearch` — `.git`, `node_modules`, `Pods`, `DerivedData*`, `*.build`, and friends.
- [x] Run the walk off the main thread; a large repository must not freeze the tab.
- [x] Build a real tree — folders with their files nested — not a flat list, because 67 files flat is unusable.
- [x] Sort folders before files, each alphabetically, so the order is stable between scans.
- [x] Surface the count, and an empty state when a repository has no markdown at all.
- [x] Refresh on demand, and when the repository changes.

### 02. Block parser

- [x] Define a `MarkdownBlock` value covering every element in the table above.
- [x] Parse line by line into blocks; keep it pure — a `String` in, `[MarkdownBlock]` out, no I/O.
- [x] Fenced code: capture the language, and do not parse anything inside the fence.
- [x] Handle an unterminated fence at end of file without dropping the content.
- [x] Lists: track indent depth for nesting, ordered start values, and task-list markers.
- [x] Tables: parse the delimiter row for per-column alignment, tolerate ragged rows.
- [x] Block quotes: strip one `>` level and recurse so nested quotes work.
- [x] Treat a line of `---` as a rule, but as a heading underline when it follows a paragraph, and as front-matter delimiters at the very top of a file.
- [x] Skip YAML front matter rather than rendering it as a table.
- [x] Never crash or hang on pathological input — unclosed fences, 10,000-line files, mixed tabs and spaces.

### 03. Inline rendering

- [x] Convert inline spans with `AttributedString(markdown:options:)` using `.inlineOnlyPreservingWhitespace`.
- [x] Fall back to plain text when a line fails to parse, rather than showing nothing.
- [x] Keep inline code visually distinct from surrounding text.
- [x] Make links open in the default browser, and only `http`, `https`, and `file` schemes.
- [ ] Resolve relative links against the document's own folder. **Not done:** relative image sources resolve, but relative *links* are handed to SwiftUI as-is and will not open. Needs a link-handling hook on the rendered text.

### 04. Viewer

- [x] Render blocks in a scroll view with GitHub-like vertical rhythm.
- [x] Headings: six sizes, with a rule under H1 and H2.
- [x] Code blocks: monospaced, filled background, horizontal scroll, language label, copy button.
- [x] Tables: aligned grid, header emphasis, horizontal scroll so a wide table cannot break the layout.
- [x] Quotes, rules, task boxes, and nested lists all visually distinct.
- [x] Local images resolved relative to the file; missing or remote images show a labelled placeholder.
- [x] Keep the whole document selectable and copyable.
- [ ] Respect the app's text-size and density preferences. **Not done:** the renderer uses its own type scale; `appTextScale` and `appRowSpacing` are not read yet.
- [x] Work in light and dark.

### 05. Explorer and tab integration

- [x] Add the tab to `RepositoryDetailView.DetailTab` and the picker.
- [x] Two-pane layout: file tree left, rendered document right, with a draggable divider.
- [x] Expandable folders; remember which are open while the repository stays selected.
- [x] Show the selected file's name and path above the document.
- [x] Filter box that matches on file name and folder.
- [ ] Actions on the document: Reveal in Finder, Copy Path, Open in default editor. **Reveal in Finder and Copy Path are done; Open in default editor is not.**
- [x] Empty states for no markdown found, nothing selected, and a file that has since disappeared.
- [x] Handle a file deleted or changed on disk between selection and read.

### 06. Tests

- [x] Headings at all six levels, including `#hash` with no space, which is not a heading.
- [x] Fenced code with and without a language, and an unterminated fence.
- [x] Nested bullets, ordered lists with a non-1 start, and task list markers.
- [x] Tables with each alignment, and a ragged row.
- [x] Block quotes, including nested.
- [x] Front matter is skipped, not rendered.
- [x] `---` disambiguated between rule, setext heading, and front matter.
- [x] Inline spans survive the round trip; a malformed span degrades to plain text.
- [x] File discovery skips the noise directories and builds the expected tree.
- [x] A large synthetic document parses well inside a sensible time budget.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| 01 — File discovery | 7 / 7 | Done |
| 02 — Block parser | 10 / 10 | Done |
| 03 — Inline rendering | 4 / 5 | Done (relative links open) |
| 04 — Viewer | 8 / 9 | Done (text-size preference open) |
| 05 — Explorer and tab | 7 / 8 | Done (open-in-editor open) |
| 06 — Tests | 10 / 10 | Done |
| **Total** | **46 / 49** | **Shipped** |

## Verified in the running app

The Docs tab renders `Support/build-release/logs/README.md` with an H1 carrying GitHub's
underline rule, body paragraphs, a fenced code block with its `text` language label and a Copy
button, and inline links in the accent colour. The tree shows folders above files, with a filter
box and a live document count.

## A real defect this pass caught

The first run reported **50 documents** and opened `README 2.md` from inside
`build/Debug/LXC-BRM.app/Contents/Resources/`. A built `.app` bundles a copy of every README as
a resource, and because the walk recurses directories by hand, `skipsPackageDescendants` never
applied. **45 of those 50 entries were build artifacts.**

Skipping now also excludes directories ending in `.app`, `.framework`, `.bundle`, `.xcarchive`,
`.dSYM`, `.build`, `.xcodeproj`, `.xcworkspace`, `.playground`, and `.lproj`. The count dropped
to **31**, which matches the number of genuine documents in the repository exactly. A regression
test pins it.
