# worklog

This is the only folder that keeps an active todo file. `shared`, `frameworks`, `build-release`, and `context` do not get their own — every task, no matter which folder it touches, is tracked here with that folder named in the task text.

## This Is What We Will Be Doing

1. All todo items live in `todo-YYYY-MM-DD.md` in this folder, and nowhere else.
2. Each todo file is built from `context/requirements.md` (the in-repo copy of the functional requirements) plus the recorded decisions in `context/decisions/` — not invented ad hoc.
3. Work is broken into numbered **phases** that ship in order — each phase is a reviewable slice of the requirements, not the whole app at once. A phase doesn't start until the previous one is functional.
4. Each todo file has a `## Phases` section (numbered phases, numbered subtasks) and a `## Tracking` table with one row per phase.
5. Nothing is marked `Done` in the tracking table until the matching code exists and builds. `Open` means not started; `In Progress` means started but incomplete; `Done` means shipped and verified.
6. After the todo file changes, `worklog-YYYY-MM-DD.md` gets a short narrative update — what changed and why — so the todo stays the checklist and the worklog stays the story.
7. If a requirement conflicts with a recorded decision, the decision wins, and the conflict gets written down in `context/decisions/`.

## Active Files

- `todo-2026-08-16.md` — the master running checklist and tracking table.
- `worklog-2026-08-16.md` — the narrative log of what was actually done, verified against the checklist.

## How To Use This Folder

- New task → add it to `todo-2026-08-16.md` under the right lettered section (or a new one), with a tracking row.
- Status change → update the `Status` column in the same file, same day.
- Work finished → summarize it in `worklog-2026-08-16.md`, and only then flip the todo row to `Done`.
- New day → start a new dated pair (`todo-YYYY-MM-DD.md`, `worklog-YYYY-MM-DD.md`); carry open items forward instead of leaving them stranded in an old file.
- Any other support folder that needs a task tracked: write the task here, name the folder in the text, link back to this file from that folder's README.
