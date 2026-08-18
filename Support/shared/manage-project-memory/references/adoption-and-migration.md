# Adoption and migration

## Contents

1. Scan and diagnose
2. Choose an adoption strategy
3. Bootstrap safely
4. Map existing systems
5. Migrate without losing history
6. BRM reference adapter
7. Improvement priority

## Scan before restructuring

Inspect:

- Repository instructions and ownership files
- Root and documentation READMEs
- `docs/`, `documentation/`, `Support/`, `.github/`, `adr/`, `rfcs/`, `plans/`, and issue templates
- Requirements, roadmap, changelog, decisions, diagrams, and release instructions
- CI, generators, linting, tests, packaging, and deployment configuration
- Tracked and ignored assets
- Current worktree changes

Diagnose:

- Competing sources of truth
- Unindexed or orphaned documents
- Requirements mixed with delivery state
- Speculation represented as committed work
- Decisions rewritten instead of superseded
- Status unsupported by evidence
- Manual counts or duplicated task lists
- Asset ownership and runtime/reference confusion
- Stale names, paths, versions, commands, screenshots, and test counts

Report before mutating when the user requested only an audit or when migration choices materially
change repository structure.

## Choose an adoption strategy

### Strict

Use for a new or deliberately standardized repository. Install the standard `Support/` scaffold
and route all management artifacts through it.

### Hybrid

Use by default. Create one Support front door and link mature existing systems:

| Existing record | Lexvora role |
| --- | --- |
| `docs/architecture/` | Current architecture |
| `adr/` | Decisions |
| `rfcs/` | Research/proposals; separate accepted delivery work |
| GitHub issues | External task coordination, linked from canonical plans |
| `CHANGELOG.md` | Released outcome history, not active plan |
| CI artifacts | Verification evidence source |

Do not copy these records into Support merely for visual uniformity.

### Preserve existing

Use when established governance or tooling makes structural migration costly. Add missing contracts
and indexes in the existing locations. Record the mapping in the project profile or handbook.

## Bootstrap safely

1. Confirm the repository lacks a coherent equivalent.
2. Select profile dials with the user or infer conservative defaults.
3. Run the scaffold helper without overwrite flags.
4. Replace placeholders with facts verified from the repository.
5. Enable only areas with real ownership.
6. Create asset folders only when assets exist.
7. Run `sync`, then `audit`.
8. Add CI enforcement only after the repository passes locally.

Never claim generated template prose describes the product until it has been filled from evidence.

## Migrate without losing history

1. Inventory every old tracker and its inbound links.
2. Select the canonical owner for each distinct task or fact.
3. Move or rewrite current state into the new owner.
4. Preserve historical records or add a retired-file map showing where content went.
5. Append decisions that supersede old governance rules.
6. Update links and generators.
7. Compare task counts and statuses before and after migration.
8. Run the project build/test checks when documentation participates in packaging or runtime.
9. Remove an obsolete tracker only after its content and references are accounted for.

Do not manufacture false continuity. Record what was true before migration and what is true now.

## Keep external tools subordinate to repository truth

GitHub, Linear, Jira, or another tracker may coordinate people, but the repository must retain the
minimum durable context needed to understand shipped code. Link external identifiers from plans
and evidence. Do not silently let inaccessible external data become the only explanation.

## Apply the BRM reference adapter

When these files exist, treat BRM as a strict Lexvora reference implementation:

1. Use capitalized `Support/`.
2. Read `Support/README.md`, `Support/context/rules-context.md`,
   `Support/context/architecture.md`, requirements and decisions, then
   `Support/worklog/BRM-Plan-todo.md` and the owning plan.
3. Keep Research topics under `Support/research/` with `Stage`, `Opened`, and `Question` metadata
   and no checkboxes.
4. Keep committed work in one `Support/worklog/Plan-<Area>-todo.md`; keep the master index task-free.
5. Keep durable design sources in `Support/context/concepts-designs/`; keep plan-specific proof in
   `Support/worklog/assets/<area>/`; keep runtime resources under `App/Resources/`.
6. Prefer BRM's repository-specific generator:

   ```sh
   python3 Support/build-release/scripts/update-plan-index.py
   python3 Support/build-release/scripts/update-plan-index.py --check
   ```

7. Record cross-cutting proof in `Support/worklog/Plan-QualityVerification-todo.md` and release
   work in `Support/worklog/Plan-ReleasePackaging-todo.md`.
8. Include ignored `Support/build-release/version/*.md` in authored-document audits; exclude apps,
   DMGs, and packaged documentation duplicates.

Do not retrofit `Support/project-system.yaml` or the generic index format into BRM automatically.
BRM's existing rules and generator remain authoritative until an explicit migration is requested.

## Improve in priority order

Apply the smallest high-value correction first:

1. Resolve source-of-truth and ownership conflicts.
2. Separate Research from committed delivery.
3. Repair decision precedence and historical supersession.
4. Make completion claims evidence-backed.
5. Repair links, names, paths, and asset ownership.
6. Generate indexes and counts that currently drift by hand.
7. Add profile/scaffold consistency.
8. Add CI enforcement only after the operating model is stable.

Keep changes focused and reviewable. Do not transform an audit into an unauthorized migration.
