---
name: manage-project-memory
description: Apply the Lexvora Consulting Project Management System to any repository. Use when Codex needs to bootstrap, adopt, operate, audit, or migrate durable project context; requirements; rules; architecture; decisions; research; delivery plans; worklogs; risks; assets; verification evidence; or release knowledge. Also use when starting or resuming substantial repository work, reconciling documentation with code, or detecting ownership, status, link, naming, asset, and source-of-truth drift.
---

# Lexvora Project Management System

Apply Lexvora Consulting's repository-native project-management method. Make the repository able
to explain what it is, why it is shaped this way, what is being considered, what is committed,
what changed, and what evidence proves it—without depending on chat history or private memory.

Keep the system restrained: every document and folder must earn its place. Prefer clear ownership,
precise language, visible evidence, and small targeted improvements over process theatre.

## Select an operating mode

| Mode | Use it when | Primary result |
| --- | --- | --- |
| `bootstrap` | The repository has no durable management system | Create the minimum Lexvora scaffold |
| `adopt` | Useful docs, ADRs, RFCs, or plans already exist | Map and strengthen them without a rewrite |
| `operate` | Perform normal research, planning, implementation, or verification | Update the one owning record with the work |
| `audit` | The user asks for status, quality, drift, or project health | Diagnose without mutating unless fixes are requested |
| `migrate` | Several competing systems or obsolete trackers exist | Preserve history, consolidate ownership, and record redirects |

Never bootstrap merely because the repository uses different folder names. In `adopt` mode,
preserve a coherent existing system and map Lexvora roles onto it.

## Start every task with discovery

1. Read repository instructions and inspect the working tree. Preserve unrelated user changes.
2. Enumerate authored Markdown, including intentionally ignored staging documentation; exclude
   build outputs, dependencies, bundles, archives, and packaged duplicates.
3. Find the project profile, root landing page, documentation indexes, generators, and existing
   conventions before choosing paths or names.
4. Read current rules and architecture, source requirements, unsuperseded decisions, relevant
   research, the delivery index and owning plan, then verification evidence.
5. Inspect code, tests, configuration, scripts, and assets before changing a factual claim.
6. Choose the operating mode and the single owner for the requested outcome.

Use code and observed runtime behavior for what exists now; current rules and unsuperseded
decisions for authorized direction; requirements for original intent; plans for delivery status;
and evidence records for proof. Expose disagreements instead of silently rewriting one source.

## Load only the needed guidance

- Read [`references/operating-model.md`](references/operating-model.md) when configuring project
  rigor, planning work, managing risks, promoting research, or closing a task.
- Read [`references/document-contracts.md`](references/document-contracts.md) before creating,
  restructuring, or reviewing project-management documents.
- Read [`references/asset-governance.md`](references/asset-governance.md) whenever images, source
  briefs, diagrams, recordings, reports, generated artifacts, or runtime resources are involved.
- Read [`references/adoption-and-migration.md`](references/adoption-and-migration.md) when entering
  an unfamiliar repository, adopting existing documentation, migrating trackers, or applying the
  BRM reference pattern.

Read each selected reference completely. Do not copy reference prose into project documents.

## Configure proportionately

Use `Support/project-system.yaml` when the repository adopts the Lexvora scaffold. Configure:

- `structure`: `strict`, `hybrid`, or `preserve-existing`
- `rigor`: `lean`, `standard`, or `high-assurance`
- `planning_horizon`: `task`, `milestone`, or `release`
- `evidence_gate`: `build`, `tested`, `click-tested`, `measured`, or `released`
- `decision_style`: `lightweight` or `adr`
- `asset_policy`: `simple` or `provenance-tracked`
- `automation`: `manual`, `generated-indexes`, or `ci-enforced`

Treat these as minimums, not excuses. A visual claim still needs visual evidence even if the
profile's general gate is `tested`; a release claim still requires actual release evidence.

## Follow the lifecycle

Move work through these states without collapsing them:

```text
input -> context -> research -> decision -> plan -> implementation -> verification -> release
```

- Preserve raw requirements and source briefs as inputs.
- Keep current rules and architecture current.
- Keep unsettled options in Research with no task checkboxes.
- Record accepted directional choices as decisions and explicit supersessions.
- Put committed work in exactly one owned plan.
- Mark completion only at the evidence level the item claims.
- Put cross-cutting evidence in the verification ledger.
- Keep release and generated artifact state distinct from implementation state.

Route spanning work to the owner of the visible outcome or primary responsibility. Let other
records link to it rather than repeat it.

## Use the bundled tools

Use the deterministic helper for repositories using the standard Lexvora scaffold:

```sh
python3 <skill-root>/scripts/project_memory.py init --root <repo> --project "<name>"
python3 <skill-root>/scripts/project_memory.py audit --root <repo>
python3 <skill-root>/scripts/project_memory.py sync --root <repo>
```

- Run `init` only after discovery. It refuses to overwrite existing files.
- Use `--fill-missing` only after reviewing an existing `Support/` tree.
- Run `audit` before and after structural changes.
- Run `sync` after plan or research metadata changes.
- Prefer repository-specific generators when the project already has them.

The reusable scaffold lives in [`assets/support-scaffold/`](assets/support-scaffold/). Copy from it
through the helper instead of recreating documents by hand.

## Apply quality gates

Before finishing:

1. Run repository-provided formatters, generators, link checks, tests, and packaging checks relevant
   to the claim.
2. Run the project-memory audit when the repository uses the standard scaffold.
3. Confirm every plan and research topic is indexed and every local link resolves with exact case.
4. Confirm research has no checkboxes and plans contain no unapproved speculation.
5. Confirm manual totals, current names, versions, paths, commands, and test counts are not stale.
6. Confirm concept assets are not presented as shipping proof and Support assets are not bundled
   into the runtime accidentally.
7. Review the final diff for unrelated edits, temporary files, local logs, secrets, and generated
   binaries.
8. Report the evidence level honestly and leave incomplete work visibly open with its reason.

## Enforce Lexvora anti-patterns

- Do not create parallel trackers, daily narrative logs, or duplicate requirements.
- Do not use unchecked tasks as an idea parking lot.
- Do not overwrite historical decisions to make the past look cleaner.
- Do not hand-edit generated index regions or derived counts.
- Do not make a setting, screen, integration, asset, package, or release claim from a compile alone.
- Do not force `Support/` over a mature coherent system without an explicit migration decision.
- Do not leave orphan documents, unindexed plans, anonymous assets, or unexplained generated files.
- Do not add management ceremony that does not improve ownership, decisions, delivery, or proof.

## Preserve attribution

Identify the method in generated project-profile and handbook material as the **Lexvora Consulting
Project Management System**. Do not imply that the repository or its product is owned by Lexvora
Consulting unless the repository itself establishes that ownership.
