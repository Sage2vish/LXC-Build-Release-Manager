# Plan — Xcode project & IDE

Everything about `LXC-Build-Release-Manager.xcodeproj` itself: target membership, build settings, schemes, and the
mechanics of keeping the project file correct as source files come and go.

## Why this needs a plan

The project uses **explicit file references** — it is not a filesystem-synchronised group. Every
new Swift file must be added to `project.pbxproj` in four places (file reference, build file,
group membership, and the target's Sources phase) or it silently will not compile into the app.
Every file added during this work has needed that by hand, and a missed entry shows up as
`cannot find 'X' in scope`, which reads like a code error rather than a project one.

## Current state

| Setting | Value | Note |
| --- | --- | --- |
| Deployment target | macOS 15.0 | |
| Swift version | 6.0 (both target configs) | Project-level Release still says 5.0; the target overrides it |
| Third-party packages | None | Deliberate; see the refactoring plan's non-goals |
| Code signing | Disabled for Debug | `CODE_SIGNING_ALLOWED=NO` |
| Targets | App + `LXC-Build-Release-ManagerTests` | No UI-test target |
| Known regions | en, hi | |

## 01. File registration

- [x] Every Swift file added so far is registered in the app or test target exactly once.
- [x] `Localizable.xcstrings` registered as a resource, and Hindi added to `knownRegions`.
- [x] `*.profraw` / `*.profdata` ignored, so `xcodebuild test` stops dropping coverage artifacts
      into the project root.
- [x] **Fixed a structural mess of my own making.** Every file added during this work was
      anchored to the Views group and carried no `name` attribute, so Xcode displayed the full
      path (`App/Models/HTMLSupport`) and filed Models, Services and Resources files all under
      Views. All 31 references now carry a display name and sit in their real group, Resources
      has its own group, and the dangling `BUILD_SCREEN_TODO.md` reference is gone.
- [ ] Add a check that every `.swift` file under `App/` and `Tests/` appears in the right target,
      so a missed registration is caught before it becomes a confusing scope error.
- [ ] Decide whether to migrate to a filesystem-synchronised group, which would remove this whole
      class of problem — weighing that against the churn to an actively edited project file.
- [x] Stop shipping reference material inside the app. The bundle carried a recursive copy of the
      app itself (32MB), the staged `.dmg`, fifteen design mockups, the requirements PDF, the
      shell scripts and every markdown plan — **56MB down to 11MB**. `DEVELOPMENT_ASSET_PATHS`
      removed; Resources now holds only the background asset and the Hindi strings.

## 02. Build settings

- [ ] Reconcile the Swift version: the project-level Release config says 5.0 while both target
      configs say 6.0. It works, but the mismatch is a trap.
- [ ] Review warnings; the build is clean today, and it should stay that way deliberately.
- [ ] Decide on code signing for Release, which is currently unconfigured.

## 03. Test target

- [ ] Add a UI-test target. It is the blocker on the accessibility item that has been open since
      the Build screen work — `XCUIApplication().performAccessibilityAudit()` needs one.
- [ ] Split the test files by domain once the production seams exist.
      *(Carried from the refactoring plan, section 08.)*

## 04. Hygiene

- [ ] Keep folder groups matching the folder structure: `Models`, `Services`, `Views`.
- [ ] Remove stale references when a file is deleted, rather than leaving dangling entries.
- [ ] Validate `project.pbxproj` with `plutil -lint` after any scripted edit.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| 01 — File registration | 5 / 7 | In progress |
| 02 — Build settings | 0 / 3 | Open |
| 03 — Test target | 0 / 2 | Open |
| 04 — Hygiene | 0 / 3 | Open |
| **Total** | **5 / 15** | **In progress** |
