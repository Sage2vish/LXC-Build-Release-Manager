# Legacy Support Traceability — Context, Worklog, and ProjectOps v2

> Preserve the existing Context and Worklog; use ProjectOps v2 as a governed routing and assessment layer.

## Preservation Decision

`Support/context/` and `Support/worklog/` remain in place. They are not deleted or rewritten. Their records are historical and operational evidence for the project.

ProjectOps v2 adds `Support/documentation/` and new governance masters. It does not automatically replace the old Worklog task system.

## Existing-to-ProjectOps Mapping

| S.No. | Existing source | ProjectOps destination | State |
| ---: | --- | --- | --- |
| 1 | `Support/context/requirements.md` | `Support/documentation/project-analysis.md` and future traceability | Analysed; unchanged |
| 2 | `Support/context/architecture.md` and diagrams | `Support/documentation/product-architecture.md` | Summarised; originals preserved |
| 3 | `Support/context/decisions/` | Concept, architecture, and decision evidence | Referenced; preserved |
| 4 | `Support/context/concepts-designs/` | `CON001` and future concepts | Incorporated into concept evidence |
| 5 | `Support/worklog/BRM-Plan-todo.md` | `Support/plans/plans-master.md` | Legacy index remains operational |
| 6 | `Support/worklog/Plan-*-todo.md` | Future ProjectOps plans by area | Migration pending, area by area |
| 7 | `Support/research/` | ProjectOps research/concept references | Preserved and not counted as delivery |
| 8 | Git history | `CON001` history and documentation evidence | Historical authors and milestones recorded |

## Worklog Deployment Status

The old Worklog has **not** been copied wholesale into `Support/plans/`. The new ProjectOps plan shell is currently empty. This is intentional: copying all legacy plans would create two competing task systems and could corrupt the existing counts.

- The legacy Worklog index and all area plans remain present.
- The legacy Worklog remains the detailed delivery ledger: 734 of 901 items done at the last recorded index state.
- `Support/plans/` is a ProjectOps shell, not yet a task-for-task migration.
- Migration must happen one owning area at a time with source links and verified statistics.

## Safe Migration Rule

1. Select one legacy `Plan-*-todo.md` area.
2. Compare its boundary, task markers, shipped evidence, and open items.
3. Create or update one ProjectOps plan with a source link.
4. Run `pdm sync Support --fix`, documentation audit, and context check.
5. Commit and push that batch.
6. Mark the legacy source as mapped only after verification.

## Navigation

Concept history: [`../concept-design/CON001_Initial_Concept.md`](../concept-design/CON001_Initial_Concept.md) · Legacy master:
[`../worklog/BRM-Plan-todo.md`](../worklog/BRM-Plan-todo.md) · Context:
[`../context/README.md`](../context/README.md)
