# CON001 — Initial System Concept: An Inspectable Release Room

> **Parent:** [`concept-design-master.md`](./concept-design-master.md) · **Date opened:** 2026-08-16  
> **Enriched:** 2026-09-21 · **Status:** Historical baseline / enriched from repository evidence

## Concept Summary

LXC Build Release Manager is a native macOS workspace that turns a repository's existing build and release scripts into a visible, inspectable operating room. It discovers the build contract, runs local work from the correct checkout, streams evidence, preserves results, and guides deliberate release packaging.

## The Problem

Build and release knowledge normally lives in shell scripts, folder conventions, logs, preferences, and individual memory. The product makes the following visible without hiding the underlying work:

- Which scripts are available?
- Which repository and branch am I acting on?
- What happened during the last run?
- Where is the evidence?
- Is output only staged locally, or intentionally published?

## Conceptual Flow

```mermaid
flowchart LR
    A[Repository] --> B[Discover contract]
    B --> C[Run locally]
    C --> D[Observe output]
    D --> E[Preserve evidence]
    E --> F[Stage release]
```

## Historical Evolution

| S.No. | Period / evidence | What changed | Concept significance |
| ---: | --- | --- | --- |
| 1 | 2026-08-16 requirements and decisions | Native macOS direction, Support areas, local release staging, and first workspace structure established | Chose an inspectable desktop product over the original cross-platform proposal |
| 2 | 2026-08-17 implementation history | Build, Logs, History, Overview, Preferences, localization, Markdown Docs, and refactoring work landed | Expanded the idea into a complete release workspace |
| 3 | 2026-08-18 Worklog decision | Dated todo files retired; one master index and one plan per area adopted | Made delivery traceable without duplicate task systems |
| 4 | 2026-08-18 restructure | `LXC-BRM/` removed, product identity clarified, Support synchronized with Xcode | Made the repository itself easier to inspect and operate |
| 5 | 2026-08-18 release/research separation | DMG staging matured and research moved beside Worklog | Separated committed delivery from unsettled questions |
| 6 | 2026-08-22 hardening | Self-identification scan and run script added | Strengthened repository identity and self-hosting |
| 7 | 2026-09-01 latest pre-governance product commit | Punjabi localization and test fixes added by `nschabra` | Confirms continued product evolution after the original batches |
| 8 | 2026-09-21 ProjectOps adoption | Bootstrap, Adopt, Documentation Mode, and this concept enrichment added | Adds governed discovery while preserving historical records |

## Historical Ownership and Contributors

- **Sage Vish** (`sage2vish.career@gmail.com`) authored the original direction and the main implementation/documentation sequence from 2026-08-16 through 2026-08-22.
- **nschabra** (`nschabra.work@gmail.com`) authored the 2026-09-01 Punjabi localization and string-catalog/test repair.
- **Codex** added ProjectOps v2 governance and documentation on 2026-09-21; these changes do not replace historical authorship.

Representative commits:

| S.No. | Commit | Historical evidence |
| ---: | --- | --- |
| 1 | `a340929` | Architecture visuals and refactoring plans |
| 2 | `6c92119` | Dated Worklog folded into owning plans |
| 3 | `bf13f27` | Workspace flattened and codename retired |
| 4 | `96ec5c8` | Plan index made generated |
| 5 | `966ab67` | Repository made runnable by its own product; research added |
| 6 | `24a80c5` | Verification runs recorded |
| 7 | `5ffd0dd` | Research moved out of Worklog |
| 8 | `43a8ec5` | Repository self-identification scan added |
| 9 | `64845f7` | Punjabi localization and test fixes |

## Evidence Sources

| S.No. | Source | What it proves |
| ---: | --- | --- |
| 1 | [`../context/requirements.md`](../context/requirements.md) | Original functional and technical requirements |
| 2 | [`../context/architecture.md`](../context/architecture.md) | Runtime, workspace, and documentation architecture |
| 3 | [`../context/decisions/decision-2026-08-16.md`](../context/decisions/decision-2026-08-16.md) | Initial decisions and boundaries |
| 4 | [`../context/decisions/decision-2026-08-18.md`](../context/decisions/decision-2026-08-18.md) | Supersession history and Worklog restructuring |
| 5 | [`../context/concepts-designs/README.md`](../context/concepts-designs/README.md) | Visual concept and source-requirements inventory |
| 6 | [`../worklog/BRM-Plan-todo.md`](../worklog/BRM-Plan-todo.md) | Detailed delivery status and area ownership |
| 7 | [`../research/README.md`](../research/README.md) | Separation of research from committed work |
| 8 | [`../documentation/legacy-support-traceability.md`](../documentation/legacy-support-traceability.md) | Legacy-to-ProjectOps mapping |

## Product Boundaries

- GitHub sources may be inspected, but execution requires a local checkout.
- Build logs remain repository-local; application history and preferences remain application-managed.
- Local release staging is not the same as signing, notarization, or publication.
- Requirements, decisions, Worklog plans, code, and verification evidence retain distinct roles.
- Historical records remain unchanged when later decisions supersede them; newer records explain the change.

## Concept Outcome

CON001 now explains why the product exists, how it evolved, who contributed, where the evidence lives, and how the legacy Worklog relates to ProjectOps v2. The old Context and Worklog remain source records.

## Footer Navigation

Concept index: [`concept-design-master.md`](./concept-design-master.md) · Documentation:
[`../documentation/documentation-master.md`](../documentation/documentation-master.md) · Context:
[`../context/current-context.md`](../context/current-context.md)
