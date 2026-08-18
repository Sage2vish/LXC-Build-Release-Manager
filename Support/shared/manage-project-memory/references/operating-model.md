# Lexvora operating model

## Contents

1. Principles
2. Configuration dials
3. Knowledge states
4. Delivery lifecycle
5. Risk and dependency discipline
6. Evidence ladder
7. Closeout sequence

## Principles

Operate the project as a traceable system rather than a collection of notes:

- Give every durable fact and task one owner.
- Separate present truth, historical input, unresolved thinking, committed delivery, and proof.
- Preserve decisions and supersede them explicitly.
- Keep project-management material beside the code it governs.
- Scale ceremony to risk and repository maturity.
- Prefer a link to the canonical record over copied prose.
- Treat a truthful open item as healthier than an unsupported completed claim.

## Configuration dials

### Structure

| Value | Behavior |
| --- | --- |
| `strict` | Use the standard `Support/` roles and names. Best for new repositories. |
| `hybrid` | Use `Support/` as the front door while linking coherent existing ADR, RFC, docs, or issue systems. Recommended default. |
| `preserve-existing` | Map Lexvora roles onto the existing layout and add only missing contracts. |

### Rigor

| Value | Required discipline |
| --- | --- |
| `lean` | One context page, lightweight decisions, one plan, targeted evidence. |
| `standard` | Full ownership boundaries, research separation, indexed plans, evidence ledger. |
| `high-assurance` | Formal decision records, risk ownership, traceable requirements, reproducible evidence, review gates. |

### Planning horizon

| Value | Plan around |
| --- | --- |
| `task` | A small tool or short-lived repository. |
| `milestone` | A product or service moving through coherent capability milestones. |
| `release` | A versioned product whose packaging and distribution state matter. |

### Evidence gate

Set the minimum general completion gate, then raise it for claims that demand stronger proof:

| Value | Minimum evidence |
| --- | --- |
| `build` | Compiles or validates structurally. |
| `tested` | Relevant automated assertions pass. |
| `click-tested` | Running user flow is exercised where applicable. |
| `measured` | Numeric targets are sampled and recorded. |
| `released` | Artifact is packaged, inspected, and intentionally published/deployed. |

### Decision style

- Use `lightweight` for a dated decision section with choice, reason, and consequences.
- Use `adr` for one record per decision with status, context, options, choice, consequences, and
  supersession metadata.

### Asset policy

- Use `simple` for descriptive filenames, ownership, relative links, and source/runtime separation.
- Use `provenance-tracked` to also record source, date, license, sensitivity, derivation, and consumers.

### Automation

- Use `manual` only for small repositories whose indexes are cheap to inspect.
- Use `generated-indexes` when plan counts or topic lists would otherwise be copied by hand.
- Use `ci-enforced` when drift should block integration.

## Knowledge states

| State | Canonical record | Mutable? | Counted as delivery? |
| --- | --- | --- | --- |
| Input | Requirements/source brief | Preserve; annotate provenance | No |
| Present truth | Rules and architecture | Yes, with code changes | No |
| Unsettled | Research topic | Yes | Never |
| Chosen | Decision record | Append/supersede | No |
| Committed | Area plan | Yes | Yes |
| Implemented | Code/configuration/artifact | Yes | Only after plan reconciliation |
| Proved | Verification ledger | Append/reconcile | Evidence only |
| Distributed | Release record | Append | Yes, at release level |

Use authority by question:

- Ask code and observed runtime behavior what exists.
- Ask rules and unsuperseded decisions what direction is authorized.
- Ask requirements what was originally requested.
- Ask the owning plan what is committed and complete.
- Ask evidence records how strongly the claim was proved.

## Delivery lifecycle

### Intake

Capture the request, origin, affected surface, desired outcome, constraints, non-goals, and required
evidence. Do not create a task until the request is understood enough to belong somewhere.

### Context

Recover the current system before proposing changes. Update present-truth documents only when the
current architecture or rule actually changes.

### Research

Use Research for feasibility, alternatives, experiments, recommendations awaiting approval, and
questions whose answer changes scope. Keep it free of task checkboxes.

### Decision

Record a decision when the work changes direction, resolves a meaningful trade-off, introduces a
new external boundary, or intentionally deviates from requirements. Name replaced decisions.

### Plan

Create one owner for the visible outcome or primary responsibility. Write atomic outcomes and
acceptance conditions. Link neighboring records without copying their tasks.

### Implementation

Change the smallest coherent slice. Preserve user data, compatibility contracts, existing tooling,
and unrelated worktree changes. Update current-state documentation in the same change when needed.

### Verification

Select evidence from the claim, not convenience. Record failed or partial evidence and keep the
task open with a reason.

### Release and archive

Distinguish built, packaged, signed, deployed, and released. Archive or supersede obsolete plans
without deleting the route from historical references to the current owner.

## Promote research

1. Keep the topic `exploring` while gathering evidence.
2. Move it to `proposal` when one option is recommended and awaiting approval.
3. Record an accepted decision when the choice affects product direction or architecture.
4. Create or update exactly one owning plan.
5. Register the plan in the delivery index.
6. Set the topic to `promoted -> Plan-<Area>` and link the decision and plan.
7. Preserve the reasoning in Research; do not duplicate it into the plan.

Use `parked` with a reason for rejected or indefinitely deferred work.

## Risk and dependency discipline

Keep risks and dependencies in the plan that owns the threatened outcome. Add a project-level risk
record only when several plans depend on the same issue.

Record each material risk with:

| Field | Meaning |
| --- | --- |
| Risk | The uncertain event, not the consequence alone |
| Impact | What becomes false, delayed, unsafe, or expensive |
| Likelihood | Low, medium, high, or measured probability |
| Owner | The plan or person responsible for watching it |
| Mitigation | Action that reduces likelihood or impact |
| Trigger | Observable signal that activates the response |
| Status | Open, mitigated, accepted, realized, retired |

Distinguish:

- **Dependency:** something required before work can complete.
- **Blocker:** a dependency currently preventing meaningful progress.
- **Assumption:** an unproved statement the plan relies on.
- **Risk:** uncertainty that may affect the outcome.
- **Constraint:** a boundary the solution must obey.

Do not turn every inconvenience into a formal risk.

## Evidence ladder

| Level | Evidence |
| --- | --- |
| Compiled | Command and successful target result |
| Traced | Code/data path inspected end to end |
| Tested | Automated assertion and result |
| Click-tested | Running interaction and observed result |
| Measured | Method, environment, samples, and numeric result |
| Packaged | Artifact produced, opened, and inspected |
| Released | Signing/deployment/publication actually completed |

Record date, environment when relevant, exact command or interaction, result, and artifact link.
Never promote an evidence level by inference.

## Closeout sequence

1. Re-read the task and acceptance conditions.
2. Run targeted implementation checks.
3. Run repository generators and project-memory audit.
4. Update the owning plan and evidence ledger.
5. Update architecture, rules, decisions, guides, or diagrams only when their truth changed.
6. Check links, casing, assets, names, versions, counts, and generated regions.
7. Review the final diff and working tree.
8. Report completed, open, and deliberately out-of-scope work separately.
