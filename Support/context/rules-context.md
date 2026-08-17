# Rules Context

## Rules

1. Keep the tool macOS-only.
2. Keep the app sources in `App/` and `Tests/` at the repository root, beside the Xcode project.
3. Keep non-app workspace support content in the `Support/` tree.
4. Use `build-release/version/` as the final release staging folder.
5. Place the final `.dmg` in `version/`.
6. Track delivery in one plan per area, named `worklog/Plan-<Area>-todo.md`.
7. Keep each plan organized into a boundary statement, a checklist, and a tracking table.
8. Keep `worklog/BRM-Plan-todo.md` as the master index; every plan is linked from it, and it holds
   no tasks of its own.
9. Do not create dated `todo-YYYY-MM-DD.md` or `worklog-YYYY-MM-DD.md` files. The narrative of what
   shipped belongs in the plan that owns the work; cross-cutting evidence belongs in
   `worklog/Plan-QualityVerification-todo.md`.
10. Keep unproven ideas in `worklog/Research-<Area>.md`, with no checkboxes and a stated stage, so
    nothing unagreed is ever counted as work in progress. An idea becomes a plan only when it is
    agreed, and the research note then points at the plan.
11. Regenerate the plan index with
    `python3 Support/build-release/scripts/update-plan-index.py` rather than editing the counts
    by hand; CI runs the same script with `--check`.
12. Keep this repository runnable by the product itself: `build/scripts/` holds the real build,
    test and release commands, and they wrap the canonical implementations rather than forking
    them.
13. Keep the context folder updated whenever the architecture, rules, or decisions change.
14. Keep the README files as index pages that link the important files, and route them to
    `worklog/BRM-Plan-todo.md` when they point at current work.
15. Do not keep separate todo files in shared, frameworks, build-release, or context.
16. Treat PDF requirements as inputs, but follow recorded decisions when they conflict.
17. Keep every deviation from the PDF visible in the context and decision files.

## Source Of Truth

- Rules live here.
- Architecture lives in `architecture.md`.
- Decisions live in `decisions/`, dated, and a later decision names the one it supersedes.
- Delivery tracking starts at `../worklog/BRM-Plan-todo.md` and continues in the plan it links to.
- Unproven ideas live in `../worklog/Research-*.md` until they are agreed and promoted to a plan.
- Verification evidence lives in `../worklog/Plan-QualityVerification-todo.md`.
- PDF requirements are reference input; decisions are the implementation authority.
