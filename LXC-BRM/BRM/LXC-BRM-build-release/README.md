# LXC-BRM-build-release

Build and release orchestration for the macOS app.

## Output Layout

- `todo-2026-08-16.md` for the current dated release note
- `scripts/` for shell entry points
- `logs/` for timestamped build logs
- `version/` for the final versioned release package and `.dmg`
- `projects.json` for repo tracking and script mapping

## Requirement Hierarchy

- PDF requirements define the requested scope.
- Context decisions define the implementation path.
- If they conflict, follow the decision log and keep the conflict visible.
