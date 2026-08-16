# Worklog

The Worklog is the delivery ledger for LXC-BRM. It maps requirements and decisions to features, release work, verification, and the story of what actually changed.

## File ownership

| File or pattern | Role |
| --- | --- |
| `todo-YYYY-MM-DD.md` | Dated master checklist for the active release or workday. |
| `BuildScreen-plan-todo.md` | Detailed Build workspace execution record. |
| `Plan-PreferenceScreen-todo.md` | Detailed Preferences design and wiring plan. |
| `Plan-WindowLayout-todo.md` | Detailed window layout and View menu pass. |
| `worklog-YYYY-MM-DD.md` | Narrative record of work completed and verification evidence. |
| `*_OLD.md` | Historical archive; never treat it as the active tracker. |

The current master tracker is [`todo-2026-08-16.md`](todo-2026-08-16.md). Detailed feature plans live here because they are delivery records, but they must map back to the master tracker and never contradict its status.

## The mapping model

```text
context/requirements.md
        |
context/decisions/
        |
worklog/todo-YYYY-MM-DD.md
        |
feature plan -> code -> build/test evidence
        |
worklog-YYYY-MM-DD.md
```

## Status rules

- `[ ]` means the task is not complete.
- `[x]` means the matching code or documentation exists and has been verified at the task's stated level.
- A successful compile does not automatically close GUI, performance, stress, or release-distribution tasks.
- When a task changes architecture or a product rule, update Context as part of the same change.
- When a todo item is completed, add the short narrative and verification evidence to the dated worklog.

## Starting a new task

1. Find the relevant requirement and decision.
2. Add or update the corresponding master-tracker item.
3. Link a detailed feature plan when the work is larger than one checklist line.
4. Implement and verify the code.
5. Update the checklist and dated narrative together.

The worklog is the only place where release-wide workload is tracked. `shared`, `frameworks`, `build-release`, and `context` may link to it, but they do not own separate active trackers.

Return to the [Support Handbook](../README.md).
