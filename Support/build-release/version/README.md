# Release Version Staging

This folder is the local output boundary for release builds.

## Expected output

```text
version/
  LXC-Build-Release-Manager-<version>.dmg
  staging/
    LXC-Build-Release-Manager.app
```

Run the packaging flow from the repository root:

```sh
./Support/build-release/scripts/release.sh
```

Generated `.app`, `.dmg`, and `staging/` files are ignored by Git. The tracked `README.md` and `.gitkeep` preserve the directory contract without committing machine-specific artifacts.

The current release line is `0.1.2`; the existing dated local tag is `release-2026-08-16`. The local artifact is unsigned and intended for inspection or staging, not a claim of production signing or notarization.

Return to [Build and Release](../README.md) or the [Support Handbook](../../README.md).
