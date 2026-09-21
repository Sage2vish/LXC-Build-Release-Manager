# Coding Standards Profile — Lexvora Build and Release Manager

> **Parent:** [`support-master.md`](./support-master.md) · Method: `projectops-v2` · **State:** on

The default profile. A project tunes any line below or sets **State: off** in this header to opt
out; `rules.md` §8 records which. `pdm audit` checks only that this file exists while the profile
is declared on — the profile itself is reviewer-enforced, like the Rules Conformance Checklist.

## Default profile

| S.No. | Principle | What it means here |
| ---: | --- | --- |
| 1 | Loose coupling | A module depends on interfaces / contracts, not on another module's internals. |
| 2 | Reusable components | Shared behaviour is extracted to one place; no copy-paste of logic across files. |
| 3 | Dependency inversion | High-level policy does not import low-level detail; both depend on an abstraction. |
| 4 | Single responsibility | One module / function has one reason to change. |
| 5 | Documented module boundaries | Every module states what it owns and what it exposes. |
| 6 | No ad-hoc appends | New behaviour goes in the owning module through its own interface — never bolted onto an unrelated file. |

## Named presets (later)

`web-spa`, `nestjs-api`, `library` — preset overlays on the default set; not yet shipped.
