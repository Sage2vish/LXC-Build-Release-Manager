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

### 07. Inline and block HTML

Markdown files in this project use HTML for the things Markdown cannot express. A survey of every
`.md` file here found **`<br>` ×22, `<img>` ×20, `<strong>` ×16, `<sub>` ×14, `<td>` ×13,
`<a>` ×10, `<p>` ×6, `<tr>` ×5, `<table>` ×3, `<div>` ×2, `<code>` ×2** — and one `<script>`.
The root `README.md` opens with a centred `<div>` wrapping an `<img>` and a row of `<a>` links,
which currently renders as escaped source text.

GitHub renders a **whitelist** of HTML and strips the rest. That is the model to copy: unknown or
dangerous tags must never render, and nothing may execute or fetch.

- [x] Add a tag parser that reads a tag name, its attributes, and its inner content.
- [x] Define an explicit **allow list**: `img`, `br`, `hr`, `p`, `div`, `span`, `center`, `a`, `b`, `strong`, `i`, `em`, `code`, `kbd`, `sub`, `sup`, `del`, `s`, `mark`, `h1`–`h6`, `ul`, `ol`, `li`, `blockquote`, `table`, `thead`, `tbody`, `tr`, `td`, `th`, `details`, `summary`.
- [x] Define an explicit **deny list** that is never rendered and is shown escaped instead: `script`, `iframe`, `style`, `object`, `embed`, `link`, `meta`, `form`, `input`, `button`, `svg`, `video`, `audio`, `applet`, `base`.
- [x] Drop every `on*` event attribute, and reject `javascript:` and `data:` URLs, wherever they appear.
- [x] `<img>`: honour `src`, `alt`, `width`, `height`; resolve local paths relative to the document; never fetch a remote source.
- [x] `<br>`: render a real line break rather than swallowing it.
- [x] `<div align>` / `<center>`: align the content they wrap, including a centred image.
- [x] `<a href>`: render as a link, with the same scheme rules as Markdown links.
- [x] Inline tags inside a paragraph — `<strong>`, `<b>`, `<em>`, `<i>`, `<code>`, `<sub>`, `<sup>`, `<del>` — convert to their inline equivalents rather than showing as text.
- [x] `<table>`/`<tr>`/`<td>`/`<th>`: render through the existing table view.
- [x] `<details>`/`<summary>`: render as a disclosure group.
- [x] Unknown tags degrade to their inner text, so content is never lost.
- [x] Text that merely looks like a tag — `<repository>`, `<tabname>`, `<hex>` in this repo's docs — stays literal text, not a dropped element.
- [x] Tests: allow list renders, deny list stays escaped, `on*` and `javascript:` are stripped, unknown tags keep their text, and tag-shaped placeholders survive.

### 08. Preview / Source modes, with editing

Reading a rendered document is the common case, but sometimes you need the file as it actually
is — to check the exact Markdown, copy a table's pipes, or work out why something is not
rendering as expected. And once you are looking at the source, the natural next thing is to fix
it.

**Naming.** GitHub labels these *Preview* and *Code*. "Code" reads oddly for a prose document, so
this uses **Preview** and **Source** — the pairing Xcode and most editors use, accurate whether
the file is prose or a fenced script.

**Shape.** A segmented control, exactly like the Build / Logs / History / Overview / Docs /
Settings picker above it. The two modes are mutually exclusive by construction — there is no
state where both are active.

**Editing is only reachable from Source.** Preview is a reader and must never mutate a file.
Source starts read-only; an explicit **Edit** turns it into an editor. That ordering matters:
writing to a file in the user's repository is destructive if it happens by accident.

- [x] Segmented control in the document header, matching the tab picker's style.
- [x] **Preview** is the default and is selected when a document opens.
- [x] **Source** shows the file's exact bytes as text: monospaced, nothing rewritten.
- [x] Source is read-only until **Edit** is pressed; Preview has no edit affordance at all.
- [x] Edit swaps the header actions for **Save** and **Cancel**.
- [x] Save writes atomically, then re-parses so Preview reflects the new content immediately.
- [x] Cancel restores the file's content and leaves the file untouched.
- [x] Save is disabled until something actually changes, so it cannot rewrite a file needlessly.
- [x] Refuse to save when the file changed on disk after it was loaded, rather than clobbering
      someone else's edit; offer to reload instead.
- [x] Warn before discarding unsaved edits — switching mode, switching file, or leaving the tab.
- [x] Source keeps text selectable and copyable in both read-only and editing states.
- [x] Line numbers in read-only Source, so a rendering problem can be pointed at a line.
- [x] Both modes and every action carry accessibility labels.
- [x] Put the Preview / Source control **inline with** Reveal in Finder and Copy Path, on the same row. **Code change verified by build; not visually confirmed — tab clicks would not register in the automation harness.**
- [x] Tests: Preview is the default; Source is verbatim; the dirty check; the changed-on-disk
      guard; and that a save round-trips exactly, including trailing newlines.

### 09. Reading layout

Feedback after using the tab: the document does not use the width it has, the Source gutter does
not read like an editor, and the mode picker sits at the far right away from the content it
controls.

- [ ] Left-align the **Preview / Source** picker within the document header, next to the title,
      rather than pushed right with the file actions.
- [ ] Remove the fixed 900pt cap on the rendered document. Text currently stops mid-pane and
      reads as a narrow column with dead space beside it; it should flow to the pane's width.
- [ ] Keep a sane maximum measure so a very wide window does not produce unreadably long lines —
      generous, not 900.
- [ ] Give the Source gutter a real editor treatment: its own background, a separating rule, and
      dimmer line numbers, so the numbers read as a gutter rather than as a first column of text.
- [ ] Right-align the line numbers against the gutter edge, as editors do.
- [ ] Make the explorer / document divider visibly draggable, so it is discoverable that the
      panes can be resized.
- [ ] Verify the reading measure at the minimum pane width and at full screen.
- [ ] Round the file tree's corners and give it the same surface and border as the rest of the
      panel. It currently sits as a hard-edged rectangle against the pane, which reads as
      unfinished next to the rounded cards everywhere else.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| 01 — File discovery | 7 / 7 | Done |
| 02 — Block parser | 10 / 10 | Done |
| 03 — Inline rendering | 4 / 5 | Done (relative links open) |
| 04 — Viewer | 8 / 9 | Done (text-size preference open) |
| 05 — Explorer and tab | 7 / 8 | Done (open-in-editor open) |
| 06 — Tests | 10 / 10 | Done |
| 07 — Inline and block HTML | 14 / 14 | Done |
| 08 — Preview / Source modes, with editing | 15 / 15 | Done |
| 09 — Reading layout | 0 / 8 | Open |
| **Total** | **75 / 86** | **In progress** |

## Verified in the running app

The Docs tab renders `Support/build-release/logs/README.md` with an H1 carrying GitHub's
underline rule, body paragraphs, a fenced code block with its `text` language label and a Copy
button, and inline links in the accent colour. The tree shows folders above files, with a filter
box and a live document count.

## A real defect this pass caught

The first run reported **50 documents** and opened `README 2.md` from inside
`build/Debug/LXC-Build-Release-Manager.app/Contents/Resources/`. A built `.app` bundles a copy of every README as
a resource, and because the walk recurses directories by hand, `skipsPackageDescendants` never
applied. **45 of those 50 entries were build artifacts.**

Skipping now also excludes directories ending in `.app`, `.framework`, `.bundle`, `.xcarchive`,
`.dSYM`, `.build`, `.xcodeproj`, `.xcworkspace`, `.playground`, and `.lproj`. The count dropped
to **31**, which matches the number of genuine documents in the repository exactly. A regression
test pins it.
