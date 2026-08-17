import Foundation

/// The languages the app ships.
///
/// English is the development language and the fallback for any key Hindi does not define.
enum AppLanguage: String, CaseIterable, Identifiable {
    /// Follow macOS, falling back to English when the system language is neither supported one.
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

    /// Name shown in its own language, which is what users scanning a language list expect.
    var nativeName: String {
        switch self {
        case .systemDefault: return "System Default"
        case .english: return "English"
        case .hindi: return "हिन्दी"
        }
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
