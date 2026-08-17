# Context

Context is the reasoning layer for LXC-BRM. It gives contributors and AI tools the material needed to understand the product before changing code.

## Visual context

The architecture is also available as a self-contained SVG set for quick orientation and documentation previews. Start with the [Context Diagram Index](diagrams/README.md), then read the maps in order:

![LXC-BRM system context](diagrams/system-context.svg)

![LXC-BRM runtime architecture](diagrams/runtime-architecture.svg)

![LXC-BRM release flow](diagrams/release-flow.svg)

## Read in this order

1. [`rules-context.md`](rules-context.md) - non-negotiable workspace rules.
2. [`architecture.md`](architecture.md) - the current app and Support structure.
3. [`requirements.md`](requirements.md) - the functional requirements input.
4. [`decisions/`](decisions/) - dated decisions that clarify or override the input.
5. [`../worklog/BRM-Plan-todo.md`](../worklog/BRM-Plan-todo.md) - the master plan index, and the
   route to the plan that owns any given surface.
6. [`diagrams/`](diagrams/) - system context, runtime architecture, and release-flow maps.
7. [`concepts-designs/`](concepts-designs/) - screenshots, mockups, and the source requirements PDF.

## Source-of-truth rules

- Requirements explain the requested product behavior.
- Decisions explain the chosen implementation path when the requirements are ambiguous or conflict with the project reality.
- The plans under [`../worklog/`](../worklog/README.md) explain what has actually been implemented, and [`Plan-QualityVerification-todo.md`](../worklog/Plan-QualityVerification-todo.md) explains at what level it was verified.
- Code is the final authority for shipped runtime behavior.

The most important recorded implementation choice is that this product is a native macOS SwiftUI/AppKit app. The original requirements document contains an earlier Tauri/Rust/React proposal, which remains useful as historical input but is not the current stack.

## AI context contract

When an AI tool starts work, it should read this README, the rules, the architecture, the relevant decision record, and then [`../worklog/BRM-Plan-todo.md`](../worklog/BRM-Plan-todo.md) to find the one plan that owns the surface being changed. When a task changes a rule, architecture boundary, release path, or product decision, update the matching Context file in the same change.

The diagrams are orientation aids, not a replacement for code. Use them to understand boundaries quickly, then verify implementation details against the architecture table and source files.

## Tracking

Active work is tracked in [`../worklog/`](../worklog/README.md), not in this folder — start at the master index, [`BRM-Plan-todo.md`](../worklog/BRM-Plan-todo.md). Context records why the project is shaped a certain way; the worklog plans record what is being done.

Return to the [Support Handbook](../README.md).
