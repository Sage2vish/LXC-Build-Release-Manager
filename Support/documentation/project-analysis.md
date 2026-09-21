# Project Analysis — Lexvora Build and Release Manager

> **Mode:** ProjectOps v2 Documentation (`docops`) · **Date:** 2026-09-21  
> **Write boundary:** `Support/documentation/` and the derived `Support/context/` block only.

## 1. Repository Identity

`LXC Build & Release Manager` is a native macOS application built with Swift 6,
SwiftUI, and AppKit. Its purpose is to discover build and release scripts in a
repository, run them visibly from the repository root, preserve logs and run
history, and support deliberate release staging.

The repository declares no third-party runtime dependencies and is licensed under
MIT. The current README describes release `0.1.2`.

## 2. Physical Shape

| S.No. | Area | Evidence | Role |
| ---: | --- | --- | --- |
| 1 | `App/` | Swift sources, models, services, views, assets | Product implementation |
| 2 | `Tests/` | Swift test suites | Unit and resilience verification |
| 3 | `build/scripts/` | Build, test, release, staging, and helper scripts | Repository build contract |
| 4 | `Support/context/` | Requirements, architecture, decisions, diagrams, concepts | Product reasoning and evidence |
| 5 | `Support/worklog/` | Area plans and delivery ledger | Existing delivery tracking |
| 6 | `Support/build-release/` | Packaging contract, user guide, release scripts, version staging | Release operations |
| 7 | `Support/research/` | AI/ML and state/logging notes | Unsettled investigation |
| 8 | `Support/documentation/` | ProjectOps v2 documentation outputs | Governed documentation layer |

## 3. Runtime Relationship

The application presents a repository-oriented workspace. `RepositoryStore`
maintains repository identity and state; `BuildScriptScanner` and
`DeepScriptSearch` discover executable scripts; `BuildRunner` executes them from
the repository root; `LogFileService` and `BuildHistoryStore` preserve evidence;
and release scripts stage distributable output under the repository’s release
support area.

The core product boundary is explicit: a GitHub repository can be inspected,
but execution requires a local checkout with a real working directory.

## 4. Documentation Coverage

The repository already contains substantial contextual documentation and plans.
ProjectOps v2 adds the canonical documentation master and documentation plan.
There are currently no root-level `skills/<skill-name>/SKILL.md` sources in this
repository, so `pdm docs scaffold --from-skills` has no skill pages to generate.
The documentation layer therefore records the project itself and its existing
support areas rather than inventing skill documentation.

## 5. Known Reconciliation Points

- Existing worklog plans remain the historical delivery source and are not
  rewritten by Documentation Mode.
- The ProjectOps v2 repository manifest is currently lenient while the existing
  Xcode project/workspace layout is assessed against the repository taxonomy.
- Full repository checkpoint auditing still reports legacy link/concept/layout
  findings; these are evidence for later bounded remediation, not silently
  changed in Documentation Mode.

## 6. Next Documentation Pass

Document the main product verticals in `Support/documentation/`:

1. Product and runtime architecture
2. Build-script and release workflow
3. Evidence, logs, history, and repository identity
4. Existing governance and continuation path

## Footer Navigation

Parent: [`documentation-master.md`](./documentation-master.md) · Context:
[`../context/current-context.md`](../context/current-context.md)
