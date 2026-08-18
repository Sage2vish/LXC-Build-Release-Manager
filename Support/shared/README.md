# Shared

The Shared area is for reusable workspace conventions, cross-feature ideas, snippets, and notes that should be understood by more than one product area.

## What belongs here

| Good fit | Not the source of truth for |
| --- | --- |
| Naming conventions and reusable patterns | Feature completion status |
| Cross-feature data or workflow ideas | Build output or runtime history |
| Small examples that can be shared safely | Product decisions without a decision record |
| Guidance that applies to Build, Context, and Worklog | Feature-specific implementation details |

There is no shared runtime module here today. The folder is kept as a deliberate collaboration boundary so reusable ideas have a clear home before they are promoted into `App/` code.

## Lexvora project-management skill

[`manage-project-memory/SKILL.md`](manage-project-memory/SKILL.md) packages the **Lexvora Consulting
Project Management System** as a reusable Codex workflow for any repository. It includes hybrid
adoption, configurable rigor and evidence gates, document and asset contracts, a reusable Support
scaffold, and deterministic initialization, index, and audit tooling. It is intentionally stored
here rather than in Context or Worklog: the skill governs how those areas cooperate, but it is
neither product truth nor a delivery tracker.

Active work remains mapped through [`../worklog/README.md`](../worklog/README.md). Product rules and architectural decisions belong in [`../context/`](../context/README.md).

Return to the [Support Handbook](../README.md).
