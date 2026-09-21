# Project Rules — Lexvora Build and Release Manager

> **Parent:** [`support-master.md`](./support-master.md) · Method: `projectops-v2`

## 1. Governance & Boundary Rules

1. Documentation root casing: `Support`
2. Git mode: `Direct Main`
3. Theme: `lexvora-company`
4. Every governed Markdown table must contain a left-most sequence column named `S.No.` numbered 1..N.
5. Every Plan task statistics row must strictly balance `TL = PD + IP + CD`.
6. Use `_` as identifier token separator (e.g. `G_01`, `WL_YYYYMMDD_A`).
7. All mechanical calculations, worklogs, and commits are managed via the `pdm` CLI.
8. Coding-standards profile: **on** — see [`coding-standards.md`](./coding-standards.md). Execute
   mode holds delivered code to that profile the way it holds it to architecture and decisions.
