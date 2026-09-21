# Governance and Continuation — LXC Build & Release Manager

> **Method:** ProjectOps v2 Documentation Mode (`docops`).

## Reading Order

1. Read [`../rules.md`](../rules.md) for the binding documentation and statistics rules.
2. Read [`../context/current-context.md`](../context/current-context.md) for the distilled state.
3. Read [`../plans/plans-master.md`](../plans/plans-master.md) for governed delivery plans.
4. Read [`../worklog/worklog-master.md`](../worklog/worklog-master.md) for execution history.
5. Read the relevant documentation page in this folder for the product area.

## Scope Boundaries

Documentation Mode reads the application, scripts, support masters, and Git history
as evidence. Its writes are limited to `Support/documentation/` plus the derived
block of `Support/context/`. Existing plans, worklogs, architecture records, and
runtime code are not silently rewritten during documentation work.

## Current State

- ProjectOps v2 governance has been bootstrapped and adopted.
- The documentation analysis and four product documentation pages are present.
- There are no root-level skill sources for automatic skill-page scaffolding.
- Documentation audit and context drift checks pass.
- Existing legacy repository findings remain recorded for later bounded remediation.

## Continuation Rule

Every future documentation batch should follow:

1. Analyse the relevant source area.
2. Write or update only the owning documentation page.
3. Run `pdm docs audit`.
4. Run `pdm context refresh` and `pdm context check`.
5. Commit and push the completed batch.

## Navigation

Parent: [`documentation-master.md`](./documentation-master.md) · Analysis:
[`project-analysis.md`](./project-analysis.md) · Context:
[`../context/current-context.md`](../context/current-context.md)
