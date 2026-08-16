# LXC-BRM-build-release

Build and release orchestration for the macOS app.

## Output Layout

- Active todo tracking lives in `../LXC-BRM-worklog/todo-2026-08-16.md`.
- `scripts/` for shell entry points
- `logs/` for timestamped build logs
- `version/` for the final versioned release package and `.dmg`
- `projects.json` for repo tracking and script mapping

## Requirement Hierarchy

- PDF requirements define the requested scope.
- Context decisions define the implementation path.
- If they conflict, follow the decision log and keep the conflict visible.
- The build-release folder does not keep its own todo file.
- The worklog todo is the working checklist for this area.

## Build Instructions (Packaging the .app)

1. Open `LXC-BRM/LXC-BRM.xcodeproj` in Xcode.
2. Select the `LXC-BRM` scheme, target "My Mac".
3. **Debug build** (for local testing): `Product > Build`, or from the command line:
   ```
   xcodebuild -project LXC-BRM.xcodeproj -scheme LXC-BRM -configuration Debug build
   ```
   The built `.app` lands in DerivedData under `Build/Products/Debug/LXC-BRM.app`.
4. **Release build** (for distribution): `Product > Archive`, then `Distribute App > Copy App` to export a self-contained `.app`. From the command line:
   ```
   xcodebuild -project LXC-BRM.xcodeproj -scheme LXC-BRM -configuration Release build
   ```
5. Copy the exported `LXC-BRM.app` into `version/` (this folder) alongside the version number you're shipping.
6. Optional — wrap it in a `.dmg` for distribution:
   ```
   hdiutil create -volname "LXC-BRM" -srcfolder version/LXC-BRM.app -ov -format UDZO version/LXC-BRM.dmg
   ```
7. Code signing: the project currently uses "Sign to Run Locally" (automatic, ad-hoc). For distribution outside your own Mac, set a Developer ID signing identity in the target's Signing & Capabilities before archiving.
