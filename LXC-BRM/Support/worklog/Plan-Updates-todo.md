# Plan — Update Checking (`checkForUpdatesAutomatically`, `updateChannel`)

Both preferences have been stored and rendered in the General tab since the settings screen was
built, with nothing behind them. They are currently disabled with copy saying "not active yet".
This plan gives them a real implementation and re-enables them.

## Decision: where updates come from

There is no release server for this app, and adding one is out of scope. GitHub Releases on the
project's own repository is a real, already-existing feed and needs no new infrastructure:

`https://api.github.com/repos/Sage2vish/LXC-Build-Release-Manager/releases`

| Channel | Means |
| --- | --- |
| Stable (Recommended) | Newest release that is **not** a prerelease and not a draft |
| Beta | Newest release including prereleases |

This reuses the GitHub client seam the scanner already has, including the personal access token
and the rate-limit handling added in the preferences pass.

## Non-Goals

- No auto-download, no auto-install, no code-signing or Sparkle-style updater. Checking tells the
  user a newer version exists and links to it; installing stays manual.
- No new third-party dependency.
- No background daemon. The check runs at launch and on demand.

## Work Plan

### 01. Version comparison

- [x] Read the running app's version from `CFBundleShortVersionString` rather than hardcoding it.
- [x] Parse semantic versions (`0.1.2`, `v0.1.2`, `1.0`) into comparable components.
- [x] Compare correctly where string comparison fails — `0.1.10` is newer than `0.1.9`.
- [x] Treat an unparseable tag as "not newer" so junk in a release name cannot trigger a false prompt.
- [x] Handle prerelease suffixes (`0.2.0-beta.1`) so Beta can order them against stable releases.

### 02. Release feed

- [x] Add an `UpdateChecker` service that fetches the releases endpoint.
- [x] Send the same headers and optional token the scanner uses.
- [x] Map the response to a small `AvailableUpdate` value: version, name, notes URL, prerelease flag.
- [x] Apply the channel filter — Stable skips prereleases and drafts, Beta includes prereleases.
- [x] Reuse `GitHubRateLimit` so a throttled check reports the same actionable message.
- [x] Return a typed result: up to date, update available, or a failure with a reason.
- [x] Never block app launch on the network; the check is async and failure is silent to the UI.

### 03. Preference wiring

- [x] `checkForUpdatesAutomatically` gates the automatic check at launch.
- [x] `updateChannel` selects the filter, and changing it re-evaluates without a restart.
- [x] Re-enable both controls in the General tab and restore honest copy.
- [x] Add a "Check Now" action so the feature is usable with automatic checking off.
- [x] Surface the result in the settings screen — current version, newest found, and a link.
- [x] Record check failures through `DiagnosticsLog` rather than surfacing noise.

### 04. Tests

- [x] Version parsing and ordering, including `0.1.10` vs `0.1.9` and `v` prefixes.
- [x] Unparseable versions never report an update.
- [x] Channel filtering picks the right release from a mixed stable/prerelease/draft feed.
- [x] Equal versions report up to date, not an update.
- [ ] A rate-limited or failed response reports a failure rather than a false "up to date". **Not covered: needs a `URLSession` stub, which is the injected-transport seam the refactor plan's section 02 has not reached yet.**

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| 01 — Version comparison | 5 / 5 | Done |
| 02 — Release feed | 7 / 7 | Done |
| 03 — Preference wiring | 6 / 6 | Done |
| 04 — Tests | 4 / 5 | Done (network failure path untested) |
| **Total** | **22 / 23** | **Shipped** |

## Note

Equality was a real bug caught by the tests: Swift's synthesized `Equatable` compared
`[1, 0]` against `[1, 0, 0]` and called `1.0` different from `1.0.0`, which would have reported a
phantom update. `==` now pads the same way ordering does.
