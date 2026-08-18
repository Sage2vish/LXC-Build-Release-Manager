import SwiftUI

/// The two settings people reach for often enough that burying them in Preferences is wrong:
/// appearance and language.
///
/// Both follow one rule — **no label outside the control**. The segments carry their own words, so
/// nothing has to sit beside them explaining what they are, and the header keeps its width for the
/// repository name.
///
/// Neither control introduces a setting. Each drives the value Preferences already owns, through a
/// binding into `PreferencesStore`, so the two surfaces cannot drift apart: changing appearance
/// here moves Preferences → Appearance, and vice versa.

// MARK: - Appearance

/// System · Light · Dark, in that order — System first because it is the default and the one most
/// people should stay on.
struct AppearancePicker: View {
    @Binding var theme: AppTheme

    /// Ordered deliberately rather than taken from `allCases`, whose order is a declaration
    /// detail and would put System last.
    private static let ordered: [AppTheme] = [.system, .light, .dark]

    /// Below this width the words are dropped for symbols; the three positions stay identical, so
    /// muscle memory survives the switch.
    var compact = false

    var body: some View {
        Picker("", selection: $theme) {
            ForEach(Self.ordered) { option in
                if compact {
                    Image(systemName: Self.symbol(for: option))
                        .accessibilityLabel(Self.title(for: option))
                        .tag(option)
                } else {
                    Text(Self.title(for: option)).tag(option)
                }
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(maxWidth: compact ? 108 : 210)
        .help("Appearance: follow the system, or force light or dark")
        .accessibilityLabel("Appearance")
        .accessibilityValue(Self.title(for: theme))
    }

    static func title(for theme: AppTheme) -> LocalizedStringKey {
        switch theme {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    static func symbol(for theme: AppTheme) -> String {
        switch theme {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
}

// MARK: - Language

/// Every language the app actually ships, named in its own script.
///
/// The list comes from `AppLanguage`, which is also what the settings screen and the language
/// controller read, so adding a language adds an entry here for free — there is no second list to
/// forget.
struct LanguagePicker: View {
    @Binding var language: String

    /// Set when a switch needs a relaunch to finish, so the caller can say so instead of leaving
    /// a half-translated window unexplained.
    var onChangeRequiresRelaunch: (AppLanguage) -> Void = { _ in }

    private var selection: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(preference: language) },
            set: { newValue in
                language = newValue.rawValue
                onChangeRequiresRelaunch(newValue)
            }
        )
    }

    var body: some View {
        Picker("", selection: selection) {
            ForEach(AppLanguage.allCases) { option in
                // The native name is what someone scanning for their own language looks for.
                Text(option.nativeName).tag(option)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .frame(maxWidth: 150)
        .help("Language used by the app's own interface")
        .accessibilityLabel("Language")
        .accessibilityValue(AppLanguage(preference: language).nativeName)
    }
}

// MARK: - Both together

/// The pair as they sit in the main panel header: appearance, then language, right-aligned.
///
/// Grouped into one view so their placement is a layout decision rather than a rewrite — the open
/// question of whether language finally belongs here or in the status bar is answered by moving
/// this, not by rebuilding it.
struct AppearanceAndLanguageControls: View {
    @ObservedObject var preferencesStore: PreferencesStore
    var compact = false

    @State private var relaunchNotice: AppLanguage?

    var body: some View {
        HStack(spacing: 10) {
            AppearancePicker(
                theme: preferencesStore.binding(\.theme),
                compact: compact
            )
            LanguagePicker(
                language: preferencesStore.binding(\.language),
                onChangeRequiresRelaunch: { language in
                    // Only a genuine change to the override needs a relaunch; the controller
                    // reports that rather than the view guessing.
                    if AppLanguageController.apply(language) {
                        relaunchNotice = language
                    }
                }
            )
        }
        .alert(
            "Restart to finish switching language",
            isPresented: Binding(
                get: { relaunchNotice != nil },
                set: { if !$0 { relaunchNotice = nil } }
            )
        ) {
            Button("OK", role: .cancel) { relaunchNotice = nil }
        } message: {
            Text("Menus and system text change when \(Text(verbatim: appName)) is next opened. Everything else keeps working in the meantime.")
        }
    }

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? "LXC Build Release Manager"
    }
}
