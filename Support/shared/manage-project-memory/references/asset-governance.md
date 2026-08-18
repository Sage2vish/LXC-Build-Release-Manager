# Asset governance

## Contents

1. Placement model
2. Canonical-source rule
3. Provenance
4. Promotion and derivation
5. Security and privacy
6. Validation

## Place assets by lifecycle

| Role | Preferred home | Examples |
| --- | --- | --- |
| Durable source input | Context source/concepts area | Requirements PDFs, customer references, accepted mockups |
| Architecture explanation | Context diagrams area | System, runtime, deployment, and data-flow diagrams |
| Unsettled investigation | Topic-scoped Research assets | Experiment captures, benchmarks, comparison data, option sketches |
| Delivery evidence | Plan-scoped Worklog assets | GUI screenshots, recordings, test reports, measured captures |
| Reusable output material | Shared or skill assets | Templates, icons, boilerplate, fonts |
| Runtime resource | Product/package resource tree | Shipping icons, backgrounds, bundled templates |
| Generated output | Ignored build/release staging | Applications, archives, installers, coverage output |

Follow meaning rather than convenience. A screenshot can be Research evidence, design Context, or
delivery proof depending on why it exists.

## Keep one canonical source

1. Store one authoritative source asset.
2. Link every documentation consumer to it with relative paths.
3. Avoid copying the same image into Context and Worklog.
4. If the product must ship it, derive or copy a runtime resource into the product tree and record
   the source relationship.
5. Never make runtime code depend directly on Support/reference paths.

Use source and derivative names that reveal the relationship:

```text
Support/context/concepts-designs/app-icon-source.svg
App/Resources/AppIcon.appiconset/icon-512.png
```

## Record provenance

Use the owning topic, plan, or area index:

```markdown
| Asset | Role | Source | Date | License/sensitivity | State | Consumed by |
| --- | --- | --- | --- | --- | --- | --- |
| `failure-model-01.png` | Research capture | Sanitized fixture run | 2026-08-18 | Internal; no secrets | Experimental | AI research |
```

For `simple` policy, require asset, role, state, and consumer. For `provenance-tracked`, require
every column plus derivation notes when applicable.

Use descriptive, stable filenames. Include topic or plan, subject, variant, and date only where the
date distinguishes evidence:

```text
<area>-<subject>-<variant>-YYYY-MM-DD.<ext>
```

Avoid UUID-only, `image.png`, `final-final.png`, or chat-generated filenames.

## Distinguish source, reference, evidence, and runtime

- **Source:** original input whose provenance must survive.
- **Reference:** material informing direction but not proving delivery.
- **Evidence:** capture produced by a verification activity.
- **Runtime:** resource actually consumed by the shipped product.
- **Generated:** reproducible output that normally stays untracked.

Do not use a concept mockup as evidence that a UI shipped. Do not call a Worklog screenshot a
design source unless it was intentionally promoted and recorded as such.

## Promote without duplicating

When research becomes an accepted feature:

1. Keep raw experiment assets with the Research topic.
2. Link the accepted conclusion from the decision and plan.
3. Place later implementation screenshots in the owning Worklog evidence folder.
4. Place shipping resources in the product tree.
5. Record transformations when a source asset produces several runtime sizes or formats.

## Create folders lazily

Do not create empty asset hierarchies. Create a topic- or plan-scoped folder when the first real
asset arrives. Keep the folder no deeper than needed for clear ownership.

Recommended patterns:

```text
Support/context/concepts-designs/
Support/context/diagrams/
Support/research/assets/<topic>/
Support/worklog/assets/<plan-or-area>/
Support/shared/assets/
```

Adapt paths to a coherent existing repository rather than adding parallel folders.

## Protect secrets and rights

- Sanitize logs, screenshots, URLs, tokens, personal data, signing identities, and internal hosts.
- Treat model inputs and experiment captures as potentially sensitive.
- Record license and attribution for external images, fonts, datasets, and templates.
- Avoid committing proprietary source material to a public repository without authorization.
- Inspect image metadata when location, author, or device information may be sensitive.
- Keep large binary assets out of Git unless they are durable source material and repository policy
  supports their storage.

## Validate assets

Before closeout:

- Resolve every asset link with exact case.
- Confirm every indexed asset exists and every material asset has an owner.
- Confirm ignored generated output is not accidentally staged.
- Confirm Support/reference material is not bundled into runtime artifacts.
- Confirm alt text explains meaningful content.
- Confirm a source-to-runtime derivation is documented.
- Confirm no secret or sensitive fixture is visible.
- Confirm stale references were updated after rename or relocation.
