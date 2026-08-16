# Context

Context is the reasoning layer for LXC-BRM. It gives contributors and AI tools the material needed to understand the product before changing code.

## Read in this order

1. [`rules-context.md`](rules-context.md) - non-negotiable workspace rules.
2. [`architecture.md`](architecture.md) - the current app and Support structure.
3. [`requirements.md`](requirements.md) - the functional requirements input.
4. [`decisions/`](decisions/) - dated decisions that clarify or override the input.
5. [`../worklog/todo-2026-08-16.md`](../worklog/todo-2026-08-16.md) - the current implementation status.
6. [`concepts-designs/`](concepts-designs/) - screenshots, mockups, and the source requirements PDF.

## Source-of-truth rules

- Requirements explain the requested product behavior.
- Decisions explain the chosen implementation path when the requirements are ambiguous or conflict with the project reality.
- The master worklog explains what has actually been implemented and verified.
- Code is the final authority for shipped runtime behavior.

The most important recorded implementation choice is that this product is a native macOS SwiftUI/AppKit app. The original requirements document contains an earlier Tauri/Rust/React proposal, which remains useful as historical input but is not the current stack.

## AI context contract

When an AI tool starts work, it should read this README, the rules, the architecture, the relevant decision record, and the mapped worklog plan before editing. When a task changes a rule, architecture boundary, release path, or product decision, update the matching Context file in the same change.

## Tracking

Active work is tracked in [`../worklog/`](../worklog/README.md), not in this folder. Context records why the project is shaped a certain way; Worklog records what is being done.

Return to the [Support Handbook](../README.md).
