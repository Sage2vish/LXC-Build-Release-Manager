# Context Architecture Visuals

![Documentation](https://img.shields.io/badge/documentation-visual%20architecture-3155E8?style=for-the-badge&labelColor=0B1020)
![Format](https://img.shields.io/badge/assets-SVG%20%2B%20Markdown-28B487?style=for-the-badge&labelColor=0B1020)
![Scope](https://img.shields.io/badge/scope-context%20folder-FF7357?style=for-the-badge&labelColor=0B1020)

> A focused delivery plan for making the LXC Build & Release Manager easy to understand before it is opened, built, or extended.

## Brief

The `Support/context/` folder is the project's durable explanation layer. This plan turns the current architecture, GitHub boundary, local build workflow, persistence model, and release handoff into a small set of premium, source-controlled SVG diagrams and linked documentation pages.

The diagrams are documentation artifacts, not marketing illustrations. They must reflect the current SwiftUI/AppKit implementation and clearly distinguish what is implemented today from what is only a future integration.

## Delivery Rules

| Rule | Meaning |
| --- | --- |
| `[ ]` | Not finished. The work may be started, but the complete acceptance condition is not met. |
| `[x]` | Finished from the documentation side: the artifact exists, is linked, and has been verified. |
| Source of truth | Code is authoritative for runtime behavior; `Support/context/` explains the behavior and boundaries. |
| GitHub boundary | GitHub is shown as a repository and Contents API source for discovery. Remote scripts are not presented as locally executable. |
| Visual language | Use a restrained luxury palette: ink navy, electric blue, coral, mint, and lavender. Prefer high contrast and legible labels. |

## Scope Map

| Area | Primary output | Owner path |
| --- | --- | --- |
| System context | External actors, GitHub, local repository, app boundary, persistence, logs, and release output | `Support/context/diagrams/system-context.svg` |
| Runtime architecture | SwiftUI/AppKit surfaces, services, storage, filesystem, and API boundaries | `Support/context/diagrams/runtime-architecture.svg` |
| Release flow | Script discovery through build, staging, DMG creation, and optional GitHub handoff | `Support/context/diagrams/release-flow.svg` |
| Diagram index | Reading order, visual conventions, and source-of-truth notes | `Support/context/diagrams/README.md` |
| Context guide | AI/contributor entry point with visual context links | `Support/context/README.md` |
| Architecture guide | Technical ownership map with embedded diagrams | `Support/context/architecture.md` |
| Support handbook | Documentation map and feature/release story | `Support/README.md` |
| Root landing page | Public project story and link to the canonical diagram set | `README.md` |

## Work Plan

### 01. Establish the Documentation Model

- [x] Confirm the current product boundary: native macOS SwiftUI/AppKit app, macOS 15+, Swift 6.
- [x] Confirm the repository boundary: local folders are executable sources; GitHub URLs are discovery and metadata sources.
- [x] Confirm the service responsibilities from the implementation: repository storage, script scanning, deep search, build execution, history, logs, preferences, workspace state, and Git branch reading.
- [x] Confirm the persistence destinations under `~/Library/Application Support/LXC-Build-Release-Manager/` and repository-local `build/logs/`.
- [x] Confirm the release boundary: `Support/build-release/scripts/release.sh` stages the app and creates the DMG under `version/`.
- [x] Keep unverified GitHub Actions behavior out of the “implemented” architecture story.

### 02. Build the SVG Diagram Set

- [x] Create `system-context.svg` with the user/developer, GitHub repository/API, local repository, LXC Build Release Manager app boundary, persistence, logs, release output, and directional data flow.
- [x] Create `runtime-architecture.svg` with UI layers, app services, external boundaries, local filesystem, Application Support stores, and the execution-only local path.
- [x] Create `release-flow.svg` with discovery, validation, debug/test, release build, staging, DMG output, version history, and optional GitHub release handoff.
- [x] Use accessible text, explicit legends, strong contrast, and readable labels at the SVG viewBox scale.
- [x] Add stable titles and descriptions inside every SVG so the diagrams remain understandable outside a browser preview.
- [x] Keep SVGs self-contained with no remote fonts, scripts, or runtime dependencies.

### 03. Connect the Documentation

- [x] Add a diagram index at `Support/context/diagrams/README.md`.
- [x] Add the diagram set and reading order to `Support/context/README.md`.
- [x] Add visual architecture sections and implementation notes to `Support/context/architecture.md`.
- [x] Add the diagram folder to the `Support/README.md` documentation map.
- [x] Add a direct link from the root `README.md` to the canonical context diagrams.
- [x] Register this plan in `Support/worklog/README.md` without creating a competing feature todo.

### 04. Verify the Delivery

- [x] Validate every SVG as well-formed XML and confirm all referenced files exist.
- [x] Check that the diagrams agree with the architecture table, support handbook, and release script.
- [x] Check that GitHub is represented as a scan/discovery boundary and not as a falsely verified build executor.
- [x] Check that local build execution, history, logs, preferences, and release staging are all represented.
- [x] Check Markdown headings, relative links, image paths, and repository naming conventions.
- [x] Review the final diff, preserving unrelated pre-existing working-tree changes outside this documentation pass.
- [x] Mark the completed checklist lines with `[x]` only after the relevant artifact and verification step is complete.

## Acceptance Gate

The plan is complete when:

1. Three readable SVG diagrams exist under `Support/context/diagrams/`.
2. The Context and Architecture pages embed or link to the diagrams.
3. The Support handbook and root README expose the documentation path.
4. The diagram claims match the current code and release scripts.
5. XML, links, and the final working-tree scope have been checked.

## Completion Record

| Check | Result |
| --- | --- |
| Diagram assets | Complete |
| Documentation links | Complete |
| Architecture accuracy | Complete |
| SVG/XML validation | Complete |
| Final diff review | Complete |

_This file is the execution ledger for the documentation pass. Do not mark a line complete because work has merely started._
