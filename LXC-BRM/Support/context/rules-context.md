# Rules Context

## Rules

1. Keep the tool macOS-only.
2. Keep the native app inside `LXC-BRM/`.
3. Keep non-app workspace support content in the `Support/` tree.
4. Use `build-release/version/` as the final release staging folder.
5. Place the final `.dmg` in `version/`.
6. Keep dated todo files named `todo-YYYY-MM-DD.md`.
7. Keep each dated todo file organized into tasks, subtasks, and tracking.
8. Keep the context folder updated whenever the architecture or rules change.
9. Keep the README files as index pages that link the important files.
10. Keep the active worklog todo file in `worklog/todo-2026-08-16.md`.
11. Do not keep separate todo files in shared, frameworks, build-release, or context.
12. Treat PDF requirements as inputs, but follow recorded decisions when they conflict.
13. Keep every deviation from the PDF visible in the context and decision files.

## Source Of Truth

- Rules live here.
- Architecture lives in `architecture.md`.
- Decisions live in `decisions/`.
- Daily tracking lives in `../worklog/todo-2026-08-16.md`.
- PDF requirements are reference input; decisions are the implementation authority.
