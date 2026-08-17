# Research — AI and machine learning in the build room

**Stage:** exploring
**Opened:** 2026-08-18
**Question:** Where would a model earn its place in a tool whose whole value is inspectability?

No commitment, no tasks, nothing promised in the product.

> Research files are not plans. They hold thinking that has not earned a checklist yet. Nothing
> here is scheduled, and nothing here should be counted as work in progress. When one idea is
> agreed, it is promoted into a `../worklog/Plan-<Area>-todo.md` with a boundary and real items, and this file
> keeps only a line saying where it went. See [`README.md`](README.md) for that promotion path.

## The question

Where would a model earn its place in a tool whose entire value proposition is *inspectability*?

That framing matters more than the technology. This app exists because CI hides the process; a
person is responsible for shipping and wants to see what happened. Anything that answers "trust
me" instead of "here is why" works against the product, however impressive the demo. So the bar
for every idea below is the same: **does it make the evidence easier to read, or does it replace
the evidence?**

## Constraints any idea has to survive

| Constraint | Consequence |
| --- | --- |
| No third-party packages ([refactor plan's non-goals](../worklog/Plan-CodeRefactoring-Reusability-todo.md)) | Apple frameworks only: NaturalLanguage, CoreML/CreateML, Accelerate, and FoundationModels on macOS 26. No Python runtime, no vendored inference library. |
| Offline is a feature | Build logs and history are local files that open with no network. Anything requiring a server breaks that promise for the whole app, not just the new feature. |
| Deployment target is macOS 15 | FoundationModels is macOS 26+. Any on-device LLM work needs `if #available` and a defined path for people on 15. |
| Logs may contain secrets | Tokens, signing identities, internal hostnames. Nothing leaves the machine without an explicit, per-repository opt-in. This is the single hardest requirement to retrofit, so it is decided now. |
| Determinism where it counts | A build runner that is 97% right is a build runner nobody trusts. Models may **explain, rank, and suggest**. They must never decide what runs. |

## Where the data already is

Worth stating plainly, because it decides what is even possible today:

- `build-history.json` — every run: script identity, timestamp, status, duration. **Structured,
  labelled, and already accumulating.** This is the only real dataset the product has.
- `build/logs/*.log` — full stdout/stderr per run, timestamped per line. Unstructured but rich, and
  paired with a known outcome, which is exactly what supervised training wants.
- `Support/**/*.md` — the plans, context and decisions. A corpus about the project itself.
- Preferences and workspace state — usage signals: which repository, which script, which tab.

Everything below is built on one of those four. Nothing needs data the product does not collect.

## Candidate areas, most promising first

### 01. Failure explanation — "why did this fail?"

The highest-value idea, and the one most aligned with the product. A failed build's log is a
thousand lines and the useful one is rarely the last. Surface the **causal** line, not the final
one, with the surrounding context and a plain-language summary.

- **Cheapest version first, and it is not ML:** rank lines by known compiler/linker/test-runner
  error grammar, and show the first error rather than the tail. This alone probably captures most
  of the value, and it is testable.
- **Then ML:** an on-device LLM (FoundationModels, macOS 26) summarising the ranked window into a
  sentence, always shown *next to* the real log lines it drew from, never instead of them.
- Risk: a confident wrong explanation is worse than none. Mitigation is structural — the summary
  is never the only thing on screen, and every claim links to the line that produced it.

### 02. Semantic search across the Docs tab

The Support tree is now 25+ plans. "Where does a status-bar task go?" is answerable by the index,
but only if you already know the index exists. Sentence embeddings over the markdown corpus
(NaturalLanguage's `NLEmbedding`, on-device, no LLM) turn the Docs tab into something that answers
questions instead of listing files.

- Small, self-contained, no network, and it uses an Apple framework already available on macOS 15.
- Fits an existing surface rather than inventing one — it is the [Docs tab](../worklog/Plan-MarkdownExplorer-todo.md)
  getting better search.
- Probably the best first *shipped* piece of intelligence: low risk, visible payoff, no trust cost.

### 03. Duration anomaly detection — "this build is stuck"

History gives per-script duration distributions. A run at 4× the median is usually hung, not slow.
Surfacing that while it happens is genuinely useful, and the honest implementation is a rolling
median and a threshold — **statistics, not machine learning**. Worth writing down precisely so the
project does not reach for a model where three lines of arithmetic will do.

ML only earns a place here if the pattern turns out to be multi-modal (a script that is legitimately
fast or slow depending on parameters), which the data can answer once there is enough of it.

### 04. Flakiness and failure-pattern detection

Across runs of the same script: intermittent failures, failures that correlate with a parameter
value, failures that started at a particular time. This is aggregation over `build-history.json`
plus log clustering — again mostly classical, and again valuable because it turns a pile of runs
into a claim a person can check.

### 05. Script classification and parameter inference

Guess whether a discovered script is a build, a test, or a release, from its name and contents,
and suggest the parameters it accepts. Would improve first-run experience for a repository the app
has never seen. A CoreML text classifier trained offline with CreateML fits the no-dependency rule
(the model ships as a compiled resource).

Honest caveat: filename conventions probably get 90% of this with a lookup table, and the
remaining 10% may not be worth a model in the bundle.

### 06. Release-note drafting

From commits and plan diffs since the last tag, draft the notes that go with a GitHub Release. The
project already has unusually good raw material — the plans record what shipped and why.
On-device LLM, human edits before publish, never automatic.

### 07. Ranking what you reach for

Recents, scripts and tabs ordered by actual usage rather than recency alone. Barely "ML", entirely
local, and the kind of thing people notice without being able to say why. Cheap to try.

## What this should not become

- A chat box bolted onto a build tool.
- Anything that runs, retries, or fixes a build on its own. The product's contract is that the
  human decides and the machine records.
- A cloud dependency introduced through the side door of a feature.
- A reason to add a package dependency, which would reverse a standing architectural decision for
  a speculative gain.

## Where this could go next

Nothing here is scheduled. The natural first move, if any, is **02 (semantic search over the Docs
tab)** — smallest, most self-contained, no trust cost, no network, and it lands in a surface that
already has a plan. **01 (failure explanation)** is the bigger prize, and its non-ML half is worth
doing regardless of whether a model ever appears.

Promotion, when it happens: agree the idea, write `../worklog/Plan-<Area>-todo.md` with a boundary statement
and real items, add it to the `AREAS` list in
[`../build-release/scripts/update-plan-index.py`](../build-release/scripts/update-plan-index.py),
and leave a line here pointing at it.

## Open questions for discussion

1. Is a macOS 26 requirement acceptable for one feature, if macOS 15 users simply do not see it?
2. Would you ever accept a network model with an explicit per-repository opt-in, or is on-device a
   hard line for this product?
3. Is the Docs tab the right place for semantic search, or should search be app-wide from the
   start?
4. For failure explanation, does the non-ML ranking version satisfy the need on its own?
