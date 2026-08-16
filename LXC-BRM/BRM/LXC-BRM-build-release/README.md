# LXC-BRM-build-release

Build and release orchestration for the macOS app.

## Output Layout

- Active todo tracking lives in `../LXC-BRM-worklog/todo-2026-08-16.md`.
- `scripts/` for shell entry points
- `logs/` for timestamped build logs
- `version/` for the final versioned release package and `.dmg`
- `projects.json` for repo tracking and script mapping

## Requirement Hierarchy

- PDF requirements define the requested scope.
- Context decisions define the implementation path.
- If they conflict, follow the decision log and keep the conflict visible.
- The build-release folder does not keep its own todo file.
- The worklog todo is the working checklist for this area.
