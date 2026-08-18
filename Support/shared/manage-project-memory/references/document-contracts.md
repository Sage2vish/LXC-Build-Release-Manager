# Document contracts

## Contents

1. Front door and project profile
2. Context records
3. Research records
4. Decision records
5. Delivery plans
6. Verification records
7. Indexes and current-context capsule
8. Writing and status rules

## Front door

Make the Support handbook an index, not a second source of truth. Include:

- Project purpose and repository-management philosophy
- Role and entry point for each enabled area
- Reading order
- Source-of-truth explanation
- Current plan and evidence entry points
- Maintenance commands

Do not place feature tasks in the handbook.

## Project profile

Use `Support/project-system.yaml` for machine-readable operating choices:

```yaml
schema: 1
system: lexvora-project-management
attribution: Lexvora Consulting
project: Example Project
structure: hybrid
rigor: standard
planning_horizon: milestone
evidence_gate: tested
decision_style: adr
asset_policy: provenance-tracked
automation: generated-indexes
support_root: Support
enabled:
  context: true
  research: true
  worklog: true
  verification: true
  build_release: false
  frameworks: false
  shared: true
```

Keep product ownership separate from method attribution.

## Rules

Keep current, non-negotiable project constraints in `context/rules.md`. Write directives rather
than history. Link decisions that explain surprising rules.

Recommended shape:

```markdown
# Project rules

## Product and platform
## Repository structure
## Engineering
## Documentation and tracking
## Verification and release
## Source-of-truth map
```

## Architecture

Describe the current system, not the intended roadmap:

```markdown
# Architecture

## System purpose and boundaries
## Components and ownership
## Runtime and data flow
## Persistence and external integrations
## Deployment or release boundary
## Diagrams
## Known intentional constraints
```

Use code as the final authority for current runtime behavior. Update architecture in the same
change when component ownership, flow, storage, or an external boundary changes.

## Requirements and source inputs

Preserve the original brief, transcription, or requirement set. Record source and date. Annotate
intentional deviations by linking decisions; do not rewrite the input to look consistent with the
implementation.

Avoid using completion checkboxes in requirements. Map each requirement to an owning plan from the
delivery index instead.

## Current-context capsule

Keep `context/current-context.md` compact and link-heavy:

```markdown
# Current context

**Updated:** YYYY-MM-DD
**Current milestone:** <name or none>
**Primary plan:** <link>
**Required evidence gate:** <level>

## Product in one paragraph
## Active constraints
## Active decisions
## Blockers and cross-plan risks
## Latest verified state
## Resume here
```

Do not duplicate task lists. Update only when the milestone, governing decision, blocker, or latest
verified baseline changes.

## Research topic

```markdown
# Research — <topic>

**Stage:** exploring
**Opened:** YYYY-MM-DD
**Question:** <one decision-shaped question>

## Why this question exists
## Constraints
## Current evidence
## Options and trade-offs
## Recommendation
## Open questions
## Assets and provenance
## Promotion record
```

Allowed stages:

- `exploring`
- `proposal`
- `promoted -> Plan-<Area>`
- `parked`

Never use `[ ]` or `[x]` in Research. Lists of experiments are prose protocols until work is
approved; approved experiment execution belongs in a plan.

## Decision record

For ADR style:

```markdown
# Decision — YYYY-MM-DD — <title>

**Status:** proposed | accepted | superseded | retired
**Owners:** <role or team>
**Supersedes:** <link or none>
**Related:** <requirements, research, plans>

## Context
## Decision drivers
## Options considered
## Decision
## Consequences
## Verification or review trigger
```

For lightweight style, keep the same substance in a dated section. Never edit an accepted old
decision merely to hide that the project changed direction.

## Delivery plan

```markdown
# Plan — <area>

> Owns <primary responsibility>. Does not own <nearest neighboring responsibilities>.

**Status:** proposed | active | blocked | complete | archived
**Milestone:** <name>
**Evidence gate:** <minimum level>

## Sources and decisions
## Outcomes and acceptance conditions
## Risks, assumptions, and dependencies
## Work plan
- [ ] <one observable, verifiable committed outcome>
## Already delivered
## Verification record
## Tracking
```

Write outcomes instead of vague activity. Keep partially verified or blocked work open and state
why. Do not put alternatives awaiting approval into a plan.

Use one plan per owned area. For cross-cutting work, select the owner of the visible outcome or
primary responsibility and link from neighboring plans.

## Verification ledger

Use an appendable table with stable claims:

```markdown
# Verification

## Evidence levels

| Date | Claim or surface | Level | Method | Result | Artifact |
| --- | --- | --- | --- | --- | --- |
| YYYY-MM-DD | Example flow | Tested | `command` | Passed | — |
```

Record failures and caveats. A newer row may supersede an older baseline without deleting it.

## Delivery index

Keep the master plan index task-free. It should provide:

- Current roll-up status
- Every plan and its boundary
- Where new work belongs
- Requirement-to-owner mapping where useful
- Retired-file redirects after migration

Generate counts and plan lists when automation is enabled. Do not hand-edit generated regions.

## Research index

List every topic, its question, stage, and opened date. Generate it from topic metadata when
automation is enabled. A topic that is not indexed is not discoverable project memory.

## Writing and status rules

- Use sentence case and concrete nouns.
- Prefer exact paths, commands, versions, dates, and observed outcomes.
- Avoid generic claims such as "fully complete," "production ready," or "works perfectly."
- Explain the boundary and non-goals before the checklist.
- Use relative links inside the repository.
- Keep current-state documents current and historical records historical.
- Count only task markers in delivery plans.
- Keep generated content between explicit markers.
- Treat a missing owner, missing evidence level, or broken link as project-memory debt.
