# Contributing to LXC Build Release Manager

Thank you for helping improve LXC Build Release Manager. This project values small, understandable changes that keep the native macOS app and its Support handbook in sync.

## Before you change code

1. Read the [Support Handbook](Support/README.md).
2. Read the relevant [context rules](Support/context/rules.md), architecture notes, and decision records.
3. Open the [BRM plan index](Support/worklog/BRM-Plan-todo.md), use its **Where a new task goes** table to find the plan that owns the surface you are changing, and find or add the matching item there before starting larger work.

## Local verification

Run from the repository root:

```sh
xcodebuild -project LXC-Build-Release-Manager.xcodeproj -scheme LXC-Build-Release-Manager -configuration Debug build
xcodebuild -project LXC-Build-Release-Manager.xcodeproj -scheme LXC-Build-Release-Manager -configuration Debug test
```

Use the repository's SwiftFormat and SwiftLint configuration when those tools are available. Do not mark a GUI, performance, or packaging task complete from a compile result alone.

## Documentation and plan expectations

- Update the relevant Support README when folder ownership or commands change.
- Update Context when requirements, architecture, or decisions change.
- Tick a plan item only when the matching work is complete at the level the checklist claims, then update that plan's tracking table and its count in the [plan index](Support/worklog/BRM-Plan-todo.md).
- Add verification evidence to the ledger in [Plan-QualityVerification-todo.md](Support/worklog/Plan-QualityVerification-todo.md).
- Keep tracking in one place: one plan owns one area, and there are no dated todo or worklog files.
- Keep generated `.app`, `.dmg`, logs, and local build data out of commits.

## Pull requests and issues

- Open an issue for a bug, design question, or feature proposal when discussion will help.
- Keep pull requests focused and describe how the change was verified.
- Include screenshots or a short recording when a visual macOS behavior changes.
- Follow the [Code of Conduct](CODE_OF_CONDUCT.md).

For architectural questions, start with the context and decision records, then open an issue with the specific tradeoff that needs discussion.
