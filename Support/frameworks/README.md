# Frameworks

This folder is the curated framework and integration boundary for LXC Build Release Manager. It is where we record reusable system-framework knowledge, adapters, package decisions, and compatibility notes before they become app code.

## Current framework matrix

| Layer | Current choice | Role |
| --- | --- | --- |
| Language | Swift 6.0 | Application and test implementation. |
| UI | SwiftUI | Native window, navigation, forms, inspector, and settings surfaces. |
| macOS integration | AppKit | Folder selection, save panels, Finder actions, notifications, login items, and workspace integration. |
| Core services | Foundation | Filesystem, JSON persistence, dates, URLs, processes, and networking. |
| Tests | XCTest | Build workspace, scanner, command, persistence, and runner coverage. |
| Package manager | None | No third-party package dependency is currently required. |

The app targets macOS 15 or later. When a new framework or package is introduced, document its compatibility and maintenance story before adding it to the target.

## Package and adapter record

For every future entry, record:

| Field | Example |
| --- | --- |
| Name and version | `Example SDK 1.2.3` |
| Source | Official documentation or repository URL |
| Platform range | macOS versions and architectures |
| Consumer | App target, service, or Support tooling |
| Reason | The product problem it solves |
| Update date | Last verification against the current toolchain |
| License | Compatibility with this repository's MIT license |

This keeps the folder useful for sharing code and ideas without turning it into an untracked collection of copied packages.

## Current state

There are no vendored frameworks or Swift Package Manager dependencies in this folder today. That is an intentional lightweight baseline, not an unfinished package list.

Return to the [Support Handbook](../README.md).
