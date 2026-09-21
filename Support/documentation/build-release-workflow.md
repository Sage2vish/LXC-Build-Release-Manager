# Build and Release Workflow — LXC Build & Release Manager

> **Source evidence:** `build/scripts/`, `Support/build-release/`, `README.md`, and the build/release plans.

## Script Contract

| S.No. | Script | Role |
| ---: | --- | --- |
| 1 | `build/scripts/run.sh` | Run the application workflow |
| 2 | `build/scripts/build-debug.sh` | Produce a debug build |
| 3 | `build/scripts/run-tests.sh` | Execute the test suite |
| 4 | `build/scripts/release-stage.sh` | Stage release output |
| 5 | `build/scripts/release-publish.sh` | Publish the staged release |
| 6 | `build/scripts/update-plan-index.sh` | Refresh plan-related indexing |
| 7 | `build/scripts/make-app-icon.sh` | Generate the application icon asset |

## Operational Sequence

1. Add or open a repository in the application.
2. Discover the repository's build scripts.
3. Select a script and provide any supported parameters.
4. Execute it from the repository root.
5. Observe timestamped output and retain the result.
6. Review history and logs.
7. Stage and publish a release only after the build evidence is acceptable.

## Release Support Area

`Support/build-release/` owns the packaging contract, release commands, local
artifact staging, version information, and the user-facing release guide.
The release process is deliberately separated from the application UI so the
repository retains an inspectable, repeatable release contract.

## Evidence and Failure Handling

Execution evidence includes status, duration, output, and retained log files.
Stopping a process preserves partial output for diagnosis. A GitHub repository
that cannot be checked out locally can still be inspected, but it cannot be
executed until a local working directory is available.

## Navigation

Parent: [`documentation-master.md`](./documentation-master.md) · Architecture:
[`product-architecture.md`](./product-architecture.md) · Release support:
[`../build-release/USER_GUIDE.md`](../build-release/USER_GUIDE.md)
