# Plan — Localization (`language`: English + Hindi)

The `language` preference has been stored and rendered since the settings screen was built, with
nothing behind it and no localized resources in the app. It is currently disabled with copy
saying "not active yet". This plan makes it real.

## Decision: scope of languages

Per direction:

| Language | Role |
| --- | --- |
| **English (`en`)** | Standard and main language. Development language, and the fallback for any missing key. |
| **Hindi (`hi`)** | Second supported language. |

"System Default" stays the top option and means: follow macOS, falling back to English when the
system language is neither English nor Hindi.

## How the switch works

macOS resolves an app's language from the `AppleLanguages` user default. Writing that key for
our own bundle and relaunching is the supported way for an app to override its own language
without touching system settings. A language change therefore **requires a relaunch**, and the
settings screen must say so rather than appearing to do nothing.

## Non-Goals

- Not translating the Support handbook, the worklog, the plan files, or the README.
- Not localizing build script output, log content, file paths, or repository names — those are
  user data and must stay verbatim.
- No third-party localization framework.
- Not machine-translating every string in bulk; a wrong Hindi string is worse than an English one.

## Work Plan

### 01. Resources

- [x] Mark English as the development language and add Hindi to the project's known regions.
- [x] Add a `Localizable.xcstrings` String Catalog (Xcode 15+ format) rather than legacy `.strings` pairs.
- [x] Register the catalog in the app target's resources exactly once.
- [x] Confirm the built `.app` contains the Hindi localization. `hi.lproj/Localizable.strings` is present with 47 keys. There is deliberately no `en.lproj`: English is the String Catalog's source language, so English text falls back to the literals in code.

### 02. Language selection

- [x] Replace the two-option picker with System Default / English / Hindi.
- [x] Map the stored preference to a language code (`nil`, `en`, `hi`).
- [x] Apply the choice by writing `AppleLanguages`, and clear the override for System Default.
- [x] Tell the user plainly that a relaunch is required, and offer to relaunch.
- [x] Keep the stored value stable so an existing `preferences.json` still decodes.

### 03. Strings

- [x] Localize the app shell: window title, sidebar sections, the three View menu items, status bar labels.
- [x] Localize the repository header, the five tab names, and the empty states.
- [x] Localize the Build screen: table headers, the add/find/refresh actions, parameter and command labels.
- [x] Localize the log pane controls and filter names.
- [x] Leave user data unlocalized — script names, paths, log lines, repository names.
- [x] Keep English as the fallback for any key Hindi does not define.

### 04. Tests

- [x] Preference value maps to the right language code, including the System Default case.
- [x] An unknown stored value falls back to System Default rather than breaking.
- [x] Every key present in English is present in Hindi, or deliberately falls back.
- [x] Applying and clearing the override writes and removes `AppleLanguages` correctly.

## 05. Driving it from the header picker

Added 2026-08-18. The language control moving into the top band changes how often the switch is
exercised: from "once, in Preferences" to "whenever someone feels like it".

- [ ] Confirm a live switch fully re-renders every visible surface, and name the ones that do not.
- [ ] Expose the shipped localizations as data — the picker reads them, rather than a second
      hardcoded list drifting from the string catalogue.
- [ ] Verify Hindi at the narrow panel width, where longer strings meet the tightest layout.
- [ ] Decide what happens to an in-flight build's already-emitted output on a language switch;
      log lines are the program's own words, not the app's, and should almost certainly not change.

## Tracking

| Section | Checked / Total | Status |
| --- | --- | --- |
| 01 — Resources | 4 / 4 | Done |
| 02 — Language selection | 5 / 5 | Done |
| 03 — Strings | 6 / 6 | Done (see scope note) |
| 04 — Tests | 4 / 4 | Done |
| 05 — Header picker | 0 / 4 | Open |
| **Total** | **19 / 23** | **In progress** |

## Scope note on strings

SwiftUI resolves string literals in `Text`, `Label`, and `Button` through `LocalizedStringKey`
automatically, so the 47 catalogued keys take effect without touching those call sites. Strings
assembled by interpolation, or passed around as `String` variables, do **not** localize that way
and are still English. Extending coverage is a matter of adding keys and routing those specific
call sites — the mechanism is in place and proven.

## Note

Applying the override exposed a real trap. `UserDefaults` resolves `AppleLanguages` through the
global domain, so reading it back returns the system language (`en-AE` here) even when this app
has never set an override — which would have made the first "System Default" selection look like
a change and prompt a pointless relaunch. The controller now records its own override marker
instead of trusting that read.
