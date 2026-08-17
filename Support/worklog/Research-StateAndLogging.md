# Research — how the tool keeps its own state, and how it logs itself

**Stage:** exploring — your idea, captured. No plan, no tasks, nothing scheduled.

> A research note, not a plan. It holds the question, what is actually true today, and the options
> with their trade-offs. When one option is agreed it becomes a `Plan-<Area>-todo.md`; until then
> nothing here is counted as work. See [`README.md`](README.md).

## The idea, as raised

Two questions, deliberately kept together because they are the same question seen twice:

1. **How is the state of the tool maintained?** Repositories, history, preferences, what was
   selected, what was open — where does that live, and is the mechanism right?
2. **The tool needs a logging mechanism of its own.** Not the build logs it writes for the
   repositories it manages — a record of what *the application itself* did, so its own behaviour
   is inspectable when something goes wrong.

And the design question underneath both: **is a file system the right answer, or one file, or
something else entirely?**

## What is true today

Worth writing down precisely, because the answer to "should we change it" depends on it.

### State: five JSON files, one path provider

`AppDataLocations` (in `App/Services/AppDataStore.swift`) is the single source of truth for where
data lives — `~/Library/Application Support/LXC-Build-Release-Manager/`:

| File | Holds |
| --- | --- |
| `projects.json` | The repository list, pins, last-accessed times |
| `selected-repository.json` | Which repository was active |
| `build-history.json` | Every recorded run: script, timestamp, status, duration |
| `preferences.json` | All 73 preference fields |
| `build-workspace-state.json` | Per-repository script selection and parameter values |

The properties that matter, and that any replacement would have to keep:

- One place names the paths; the stores no longer each rebuild them, which they used to, five
  times over.
- Writes are atomic, directories are created on demand, dates encode consistently, output is
  sorted so a diff is readable.
- Failures are typed (`AppDataError`) and published (`lastError`) rather than swallowed by `try?`.
- On-disk file names are a product contract — an existing install must keep loading. The codename
  rename honoured that with a one-time folder migration rather than a fresh start.
- Repository build logs deliberately do **not** live here. They belong to the repository's own
  `build/logs/`, because they are part of what the user ships.

### Logging: three separate things that are easy to confuse

| What | Where it goes | Who reads it |
| --- | --- | --- |
| **Build output** — a managed repository's stdout/stderr | `<repository>/build/logs/build-<timestamp>.log` | The user, in the Logs tab. A product feature. |
| **App diagnostics** — what the app itself did | `~/Library/Logs/LXC-Build-Release-Manager/diagnostics.log`, via `DiagnosticsLog` | Whoever is debugging the app. Off unless the Advanced preferences turn it on. |
| **Crash and system logs** | macOS, unmanaged | Console.app |

`DiagnosticsLog` exists but is thin: append a timestamped line at INFO/DEBUG/ERROR, gated by
`logInternalDiagnosticsToFile` and `verboseDebugLogging`, best-effort so it can never take down a
build. What it does **not** have: rotation or a size cap, a way to view it inside the app, any
correlation between a diagnostic line and the build run it belongs to, and — most importantly —
call sites. Almost nothing in the app actually writes to it yet.

That is the honest gap behind your question: the mechanism is there, the discipline is not.

## The design question: files, a file, or something else

### Option A — keep the JSON files (what exists)

Plain, inspectable, diffable, trivially backed up, and debuggable with `cat`. It suits a tool whose
selling point is that nothing is hidden: a user can open `build-history.json` and read their own
data. No dependency, no schema migration machinery, no daemon.

Where it hurts: every write rewrites the whole file. `build-history.json` grows without bound —
one record per run, forever. At a few thousand runs it is still fine; at a hundred thousand, a
history write becomes a visible pause, and querying "the last 5 runs of this script" means loading
everything into memory first.

### Option B — SQLite for history, JSON for the rest

`libsqlite3` ships with macOS, so this stays inside the no-third-party rule. History is the only
part of the state that is genuinely a growing, queryable log: append-only, filtered by repository
and script, aggregated for statistics. That is a database-shaped problem, and it is the one place
where the JSON model will actually break.

Preferences and the repository list are small, hand-editable, and read once — they should stay
JSON. Splitting on that line keeps the inspectability where users benefit from it and puts the
scale where it is needed.

Cost: a schema, a migration from the existing JSON, and a second persistence idiom in the codebase.

### Option C — SwiftData or Core Data for everything

Native, typed, observable, with migrations as a first-class idea. Also the option that most
directly contradicts the product: an opaque store file that a user cannot read, cannot diff, and
cannot repair by hand — in an app whose whole argument is inspectability. It also fights the
existing "these file names are a contract" decision. Recorded so the option is not silently
skipped; not recommended.

### Option D — `os_log` / `OSLogStore` for diagnostics

For the *logging* half specifically, this is the native answer: structured, categorised, privacy-
aware, near-zero cost when nobody is listening, and readable in Console.app or queryable from the
app itself through `OSLogStore`. It gives up the plain-text file that a user can attach to a bug
report — which is exactly what the existing "Run Diagnostics Report…" button in Advanced was
imagined for.

The likely shape is both: `os_log` for the live signal, and a plain-text export produced on demand
for the report.

## What I would suggest

Not a plan — a recommendation to argue with:

1. **Keep state as JSON files, but bound the growing one.** The problem is not the format, it is
   the unbounded file. Retention or rolling for `build-history.json` (as already exists for build
   logs) buys years of headroom without changing the model.
2. **Move to SQLite only when history actually hurts, and only for history.** The trigger should
   be measured, not assumed — history size and write time are cheap to record.
3. **Fix the logging discipline before the logging mechanism.** A diagnostics logger with no call
   sites is not a logging system. The valuable work is deciding *what deserves a line*: every
   state write and its failure, every build lifecycle transition, every scan result, every
   preference migration, every update check. That decision is worth more than the transport.
4. **Give every diagnostic line a correlation id.** A build run already has an identity; if
   diagnostics carry it, "what was the app doing during that failed build" becomes answerable
   instead of guessable.
5. **Then consider `os_log`** as the transport, with the file as an export rather than the
   primary sink.
6. **Make the app's own state visible inside the app.** The Advanced tab already promises "Open
   Build Manager data directory" and a diagnostics report. A small read-only view of the current
   state — sizes, record counts, last write, last error — would make the tool inspectable about
   *itself*, which is the same promise it makes about builds.

## Open questions for you

1. Is a user reading and hand-editing `build-history.json` something we want to protect, or an
   accident of the current implementation?
2. Should diagnostics be on by default? Today they are off, so the first thing anyone debugging
   has to do is ask the user to turn them on and reproduce.
3. Is a diagnostics view inside the app worth a surface, or is "open the folder" enough?
4. How long should build history live? Forever is a decision, not a default.
5. Does the tool's own state belong on screen at all — a "Health" or "About this install" panel —
   or is that a developer feature in a user's product?
