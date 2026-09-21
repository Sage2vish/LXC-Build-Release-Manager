# Evidence, Logs, and History — LXC Build & Release Manager

> **Source evidence:** `App/Services/`, `Support/build-release/`, `Support/context/`, and the existing worklog.

## Evidence Model

The product treats a build as an observable event rather than a hidden command.
A run has a selected repository and script, a process lifecycle, streamed output,
a result, timing information, and retained history.

| S.No. | Evidence | Owner | Why it matters |
| ---: | --- | --- | --- |
| 1 | Live stdout/stderr | `BuildRunner` and log presentation | Immediate diagnosis and visibility |
| 2 | Retained log file | `LogFileService` | Reproducible post-run investigation |
| 3 | Run record | `BuildHistoryStore` | Outcome, duration, and trend history |
| 4 | Repository identity | repository stores and identity scan | Prevents acting on the wrong source |
| 5 | Release staging record | `Support/build-release/` | Separates prepared artifacts from published artifacts |

## History Surfaces

History is exposed through the application workspace and is also supported by
the repository's `Support/worklog/` plans. The application history answers what
ran and what happened; the worklog answers what was intended, what was verified,
and where the next governed task belongs.

## Failure and Recovery

Partial output is valuable evidence. A stopped or failed process should remain
diagnosable through its captured output and status rather than disappearing.
Repository-local logs and application-managed history serve different purposes
and should not be treated as interchangeable.

## Navigation

Parent: [`documentation-master.md`](./documentation-master.md) · Architecture:
[`product-architecture.md`](./product-architecture.md) · Governance:
[`governance-and-continuation.md`](./governance-and-continuation.md)
