// Build Screen Premium Redesign — TODO

// This is the actionable checklist for the refined Build screen, based on your product/UI vision and feedback.

---

## 1. Design & Palette
- [x] Define premium pastel color palette and accent — Palette/colors chosen and applied to app theme assets in code. See notes here and in code comments for details.
- [x] Select and document key icons (status, actions) — SF Symbols selected for all major UI actions/status; icon mapping written in code and in this log.

Theme colors (background, surface, accent, success, error, muted) and icon mapping now defined and visible in app UI; referenced in code comments for future reference. Next: Begin scrollable build scripts table refactor.

## 2. Available Build Scripts Table
- [x] Refactor build script list into scrollable table — The build script list is now a scrollable SwiftUI table, visually styled with the new pastel palette, modern layout, and live in the main build screen.

Table scrolls smoothly and adapts to overflow; user can access all scripts regardless of list length. Next: Add “Standard” status indicator (green/red dot) to each row.
- [x] Add “Standard” status indicator (green/red dot) — Each row now shows a green dot for standard scripts and red for non-standard. Status logic is based on script location/naming convention.
  - Status indicator uses `circle.fill` with green (`#4DCB7B`) for standard and red (`#F66D6A`) for non-standard. Next: Add “Inside Repo” status indicator to each row.
- [x] Add “Inside Repo” status indicator (green/red dot) — Each script row now shows a green folder icon if inside the repo, red external drive if outside. Logic checks script path versus repo root.
  - Status uses `folder.fill` (green, `#4DCB7B`) if inside repo, `externaldrive.fill` (red, `#F66D6A`) if outside. Next: Implement folder membership logic for each script.
- [x] Implement folder membership logic for each script — Each script row now accurately reflects its folder membership: whether it's standard, inside repo, outside, or in a subfolder, using path checks and clear indicators.

Folder membership logic now robust: highlights standard scripts in `/build/scripts`, custom scripts elsewhere in repo, and flags scripts outside repo. Next: Implement “Add Build Script” button with file picker.
- [x] “Add Build Script” button (file picker) — A pastel-styled button allows users to add new build scripts using an OS file picker. New scripts are properly imported and status indicators update instantly.
  - “Add Build Script” button uses `plus.circle.fill` icon and pastel accent. Clicking opens a native file picker, and importing scripts refreshes the table with full status logic.
  - **Section complete!** Next: Move to Live Output (Log) Area features.

## 3. Live Output (Log) Area
- [x] Maximize/restore log pane functionality — Log area now supports maximize/restore with a smooth pastel transition; users can focus on logs or return to normal view.  
  Maximize button uses `arrow.up.left.and.arrow.down.right`. Log pane smoothly grows and shrinks on toggle, maintaining all features and UI consistency. Next: Add “Open in Separate Window” for log view.
- [x] “Open in Separate Window” for log view — Log can now be popped out to a separate window for focused review, with full interactivity preserved.
  - Uses `macwindow` icon. Separate log window syncs with main UI, supports maximize/restore and all log features. Next: Implement “Save Log” button (save dialog).
- [ ] “Save Log” button (save dialog)
- [ ] Apply pastel/dark blended backgrounds
- [ ] Ensure auto-scroll and line numbers robust

## 4. UI/UX Polish
- [ ] Round corners, pastel backgrounds, soft panels
- [ ] Modern font, heading, badge, icon polish

## 5. Top Bar & Repo Info
- [ ] Show repo name, Git path, status badge
- [ ] Add: Reveal in Finder, Open in Terminal, Copy Path

## 6. Script Row Contextual Actions
- [ ] Three-dot menu (“…”) on each script row (future options)

## 7. Previews & Testing
- [ ] Add/expand SwiftUI previews for all subviews
- [ ] Add unit/UI tests for new actions (file picker, save log)

## 8. Accessibility & Localization
- [ ] Audit for VoiceOver/accessibility
- [ ] Prepare all new UI for localization

---

**Mark tasks as you build!**

