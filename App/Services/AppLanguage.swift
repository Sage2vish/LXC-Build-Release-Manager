import Foundation

/// The languages the app ships.
///
/// English is the development language and the fallback for any key another language does not
/// define. Adding a language means adding one case here and its strings to the catalogue —
/// nothing else in the app keeps a second list.
enum AppLanguage: String, CaseIterable, Identifiable {
    /// Follow macOS, falling back to English when the system language is not a supported one.
    case systemDefault = "System Default"
    case english = "English"
    case hindi = "Hindi"

    var id: String { rawValue }

    /// The BCP-47 code written into `AppleLanguages`, or `nil` to clear the override.
    var languageCode: String? {
        switch self {
        case .systemDefault: return nil
        case .english: return "en"
        case .hindi: return "hi"
        }
    }

    /// The language's name in English.
    var englishName: String {
        switch self {
        case .systemDefault: return "System Default"
        case .english: return "English"
        case .hindi: return "Hindi"
        }
    }

    /// The language's name written in its own script.
    var nativeName: String {
        switch self {
        case .systemDefault: return "System Default"
        case .english: return "English"
        case .hindi: return "हिन्दी"
        }
    }

    /// How the language reads in a picker: **English name — native name**.
    ///
    /// Both halves earn their place. Someone who reads the interface in English needs to find
    /// "Hindi"; someone who reads Hindi scans for "हिन्दी" and may not recognise the English word
    /// at all. Showing one without the other excludes exactly the person the entry is for.
    ///
    /// System Default is the one exception: it names a behaviour rather than a language, so
    /// repeating it either side of a dash would be noise.
    var pickerLabel: String {
        guard self != .systemDefault else { return englishName }
        guard englishName != nativeName else { return englishName }
        return "\(englishName) — \(nativeName)"
    }

    /// An unrecognised stored value falls back to System Default rather than breaking, so an
    /// older or hand-edited `preferences.json` still loads.
    init(preference: String) {
        self = AppLanguage(rawValue: preference) ?? .systemDefault
    }
}

/// Applies the language preference.
///
/// macOS resolves an app's language from the `AppleLanguages` user default. Writing it for our
/// own bundle is the supported way to override the app's language without touching system
/// settings — and it only takes effect on the next launch, which the settings screen states.
enum AppLanguageController {
    static let appleLanguagesKey = "AppleLanguages"
    /// Our own record of what we set.
    ///
    /// Reading `AppleLanguages` back is not enough: `UserDefaults` resolves it through the
    /// global domain, so it returns the system language (`en-AE`, say) even when this app has
    /// never set an override. Relying on that would make the first "System Default" selection
    /// look like a change and prompt a pointless relaunch.
    static let overrideMarkerKey = "LXCAppLanguageOverride"

    /// Writes or clears the override. Returns `true` when the value actually changed, so the
    /// caller only offers a relaunch when one is genuinely needed.
    @discardableResult
    static func apply(_ language: AppLanguage, defaults: UserDefaults = .standard) -> Bool {
        let existing = defaults.string(forKey: overrideMarkerKey)

        guard let code = language.languageCode else {
            guard existing != nil else { return false }
            defaults.removeObject(forKey: appleLanguagesKey)
            defaults.removeObject(forKey: overrideMarkerKey)
            return true
        }

        guard existing != code else { return false }
        defaults.set([code], forKey: appleLanguagesKey)
        defaults.set(code, forKey: overrideMarkerKey)
        return true
    }

    /// The override this app set, or `nil` when following the system.
    static func currentOverride(defaults: UserDefaults = .standard) -> String? {
        defaults.string(forKey: overrideMarkerKey)
    }
}
