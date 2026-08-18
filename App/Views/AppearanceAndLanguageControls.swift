import SwiftUI

/// The two window-level settings that live in the top bar: appearance and language.
///
/// **Both are native AppKit controls, deliberately.** The first attempt drew its own capsule and
/// forced a height; neither survived contact with the toolbar — AppKit does not render custom
/// backgrounds behind toolbar items, so the appearance control appeared as three loose icons and
/// the language control as a blue hyperlink. A segmented picker and a bordered menu are drawn by
/// the toolbar itself, which is also the only way three controls get genuinely identical heights:
/// the system decides the height, not three numbers that have to be kept in agreement.
///
/// They remain two separate controls — separate `ToolbarItem`s — and neither introduces a setting;
/// each binds to the value Preferences already owns.

// MARK: - Appearance

/// A three-stop control: Bright · Default · Dark, drawn as the system's segmented capsule.
///
/// Default sits in the middle because it is the resting position, with an override either side.
struct AppearanceSlider: View {
    @Binding var theme: AppTheme

    /// Ordered deliberately rather than taken from `allCases`, whose order is a declaration detail.
    private static let stops: [AppTheme] = [.light, .system, .dark]

    var body: some View {
        Picker("", selection: $theme) {
            ForEach(Self.stops) { stop in
                Image(Self.asset(for: stop))
                    .renderingMode(.template)
                    .help(Self.help(for: stop))
                    .accessibilityLabel(Self.title(for: stop))
                    .tag(stop)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
        .help("Appearance: follow the system, or force bright or dark")
        .accessibilityLabel("Appearance")
        .accessibilityValue(Self.title(for: theme))
    }

    /// Asset names, not SF Symbols: the icons are project SVGs held as vector data, so they stay
    /// crisp at any size and tint with the label colour.
    static func asset(for theme: AppTheme) -> String {
        switch theme {
        case .light: return "theme-light"
        case .system: return "theme-system"
        case .dark: return "theme-dark"
        }
    }

    static func title(for theme: AppTheme) -> String {
        switch theme {
        case .light: return "Bright"
        case .system: return "System Default"
        case .dark: return "Dark"
        }
    }

    static func help(for theme: AppTheme) -> String {
        switch theme {
        case .light: return "Bright — always use the light appearance"
        case .system: return "Default — follow the macOS appearance"
        case .dark: return "Dark — always use the dark appearance"
        }
    }
}

// MARK: - Language

/// Every language the app ships, each written **in English and in its own script**.
///
/// A bordered `Picker`, so the toolbar draws it at the same height as the appearance control
/// beside it. The bar shows the native name; the menu carries the full `English — native` pairing,
/// where there is room for it.
struct LanguagePicker: View {
    @Binding var language: String

    /// Called when a switch genuinely changes the override, so the caller can say a relaunch is
    /// needed rather than leaving a half-translated window unexplained.
    var onChangeRequiresRelaunch: (AppLanguage) -> Void = { _ in }

    private var selection: Binding<AppLanguage> {
        Binding(
            get: { AppLanguage(preference: language) },
            set: { newValue in
                guard newValue.rawValue != language else { return }
                language = newValue.rawValue
                onChangeRequiresRelaunch(newValue)
            }
        )
    }

    var body: some View {
        Picker("", selection: selection) {
            ForEach(AppLanguage.allCases) { option in
                Text(option.pickerLabel).tag(option)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .fixedSize()
        .help("Language used by the app's own interface")
        .accessibilityLabel("Language")
        .accessibilityValue(AppLanguage(preference: language).pickerLabel)
    }
}

// MARK: - Language switching side effect

/// Applies a language change and reports whether a relaunch is needed.
///
/// Kept out of both controls so neither has to know how macOS applies a language, and so the
/// alert has one home rather than one per control.
struct LanguageChangeHandler: ViewModifier {
    @Binding var pending: AppLanguage?

    func body(content: Content) -> some View {
        content.alert(
            "Restart to finish switching language",
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })
        ) {
            Button("OK", role: .cancel) { pending = nil }
        } message: {
            Text("Menus and system text change the next time the app is opened. Everything else keeps working in the meantime.")
        }
    }
}
