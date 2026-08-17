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
10. Keep the context folder updated whenever the architecture, rules, or decisions change.
11. Keep the README files as index pages that link the important files, and route them to
    `worklog/BRM-Plan-todo.md` when they point at current work.
12. Do not keep separate todo files in shared, frameworks, build-release, or context.
13. Treat PDF requirements as inputs, but follow recorded decisions when they conflict.
14. Keep every deviation from the PDF visible in the context and decision files.

## Source Of Truth

- Rules live here.
- Architecture lives in `architecture.md`.
- Decisions live in `decisions/`, dated, and a later decision names the one it supersedes.
- Delivery tracking starts at `../worklog/BRM-Plan-todo.md` and continues in the plan it links to.
- Verification evidence lives in `../worklog/Plan-QualityVerification-todo.md`.
- PDF requirements are reference input; decisions are the implementation authority.
