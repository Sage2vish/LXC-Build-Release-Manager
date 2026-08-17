# Worklog

The Worklog is the delivery ledger for LXC Build Release Manager. It maps requirements and decisions to features,
release work, and verification evidence — and it has exactly one front door.

## Start at the master index

**[`BRM-Plan-todo.md`](BRM-Plan-todo.md)** is the entry point. It lists every plan in this folder
in a linked table — by window region, by tab, by feature, and by engineering area — with each
plan's current count. Open it, find the area you are working on, follow the link, work there.

Nothing in this folder is reachable only by browsing the directory: if a plan exists, it is
linked from the master index.

## File ownership

| File or pattern | Role |
| --- | --- |
| [`BRM-Plan-todo.md`](BRM-Plan-todo.md) | The master index. Links every plan, carries its generated counts, and says where a new task goes. Holds no tasks of its own. |
| `Plan-<Area>-todo.md` | One plan per area. Owns its own checklist, tracking table, boundary statement, and the record of what shipped. |
| `Research-<Area>.md` | Thinking that has not earned a checklist yet. No tasks, no counts, no schedule. |
| `assets/` | Images referenced by a plan. |

## Research, and how it becomes a plan

Not every idea is ready to be work. A `Research-<Area>.md` file is where an idea is explored
honestly — including the reasons it might be wrong — without pretending it is scheduled.

The rules that keep research from quietly becoming debt:

- **No checkboxes.** A research note carries no `[ ]` items, so it can never be counted as work in
  progress. The index lists it separately and counts nothing from it.
- **It states its stage.** A line reading `**Stage:** exploring` (or `proposal`, or
  `promoted → Plan-X`) near the top. The index reads that line directly.
- **It says what would have to be true.** Constraints, open questions, and the reasons an idea
  might not survive them are the substance of a research note, not an appendix to it.

**Promotion** happens when an idea is agreed, and only then:

1. Write `Plan-<Area>-todo.md` with a boundary statement, a checklist, and a tracking table.
2. Add one line to the `AREAS` list in
   [`../build-release/scripts/update-plan-index.py`](../build-release/scripts/update-plan-index.py)
   so the index picks it up in the right place and order.
3. Leave the research note in place with a pointer to the plan, so the thinking behind the
   decision stays readable.

Current research: [`Research-AI-ML.md`](Research-AI-ML.md) — where a model could earn its place in
a tool whose value is inspectability.

There are no dated `todo-YYYY-MM-DD.md` or `worklog-YYYY-MM-DD.md` files. That convention was
retired on 2026-08-18: a single dated checklist could not hold a product this size without going
stale, and a separate narrative file duplicated what the plans already recorded. Their content was
distributed into the owning plans — the mapping is in the master index under **Retired files** —
and the decision is recorded in
[`../context/decisions/decision-2026-08-18.md`](../context/decisions/decision-2026-08-18.md).

## The mapping model

```text
context/requirements.md
        |
context/decisions/
        |
worklog/BRM-Plan-todo.md          <- the index
        |
Plan-<Area>-todo.md -> code -> build / test / GUI evidence
        |
Plan-QualityVerification-todo.md  <- the cross-cutting evidence ledger
```

## Status rules

- `[ ]` means the task is not complete.
- `[x]` means the matching code or documentation exists **and** was verified at the level the item
  claims. A successful compile does not close a GUI, performance, stress, or distribution task.
- An item that cannot be finished stays `[ ]` with the reason written next to it.
- Every plan carries a Tracking table; when it changes, update the count in the master index too.
- When a task changes an architecture boundary or a product rule, update
  [`../context/`](../context/README.md) in the same change.

## Starting a new task

1. Find the relevant requirement and decision in [`../context/`](../context/README.md).
2. Open [`BRM-Plan-todo.md`](BRM-Plan-todo.md) and use the **Where a new task goes** table to find
   the owning plan.
3. Add the item to that plan — not to the index, and not to a second plan.
4. Implement and verify the code.
5. Update the plan's checklist and tracking table, the index count, and — when the verification
   level changed — the ledger in
   [`Plan-QualityVerification-todo.md`](Plan-QualityVerification-todo.md).

## Creating a new plan

Only when the work does not fit any existing plan's boundary. Name it `Plan-<Area>-todo.md`, give
it a boundary statement in the first lines, a checklist, and a tracking table, then add it to the
tables in [`BRM-Plan-todo.md`](BRM-Plan-todo.md). A plan that is not in the index does not exist.

The worklog is the only place where release-wide workload is tracked. `shared`, `frameworks`,
`build-release`, and `context` may link to it, but they do not own separate active trackers.

Return to the [Support Handbook](../README.md).
