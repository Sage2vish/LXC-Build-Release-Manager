import SwiftUI

/// The two settings people reach for often enough that burying them in Preferences is wrong:
/// appearance and language. Both live in the centre column's top band — not in the right-hand
/// inspector, which is about the selected script rather than about the app.
///
/// Both follow one rule: **no label outside the control**. The icons and the language names say
/// what they are, so nothing sits beside them explaining it, and the band keeps its width for a
/// repository name that already truncates.
///
/// Neither control introduces a setting. Each binds to the value Preferences already owns, so the
/// two surfaces cannot drift apart.

// MARK: - Appearance

/// A three-position slider: System · Light · Dark.
///
/// Built rather than borrowed from `Picker(.segmented)` because the requested behaviour is a
/// slider — one knob that travels between three stops — and a segmented picker cannot show a knob
/// moving. The knob is a single rounded rectangle that animates between positions, which also
/// makes the current state readable at a glance instead of by comparing three similar segments.
struct AppearanceSlider: View {
    @Binding var theme: AppTheme

    /// Ordered deliberately: System sits in the middle because it is the default and the
    /// resting position, with the two overrides either side of it.
    private static let stops: [AppTheme] = [.light, .system, .dark]

    private let stopWidth: CGFloat = 34
    private let height: CGFloat = 24

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.stops) { stop in
                Button {
                    withAnimation(.snappy(duration: 0.18)) { theme = stop }
                } label: {
                    Image(Self.asset(for: stop))
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .frame(width: stopWidth, height: height)
                        .foregroundStyle(theme == stop ? Color.primary : Color.secondary)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(Self.help(for: stop))
                .accessibilityLabel(Self.title(for: stop))
                .accessibilityAddTraits(theme == stop ? [.isSelected] : [])
            }
        }
        .background {
            Capsule().fill(.quaternary.opacity(0.55))
        }
        .background(alignment: .leading) {
            // The knob: one shape that travels, so the control reads as a slider rather than as
            // three buttons that happen to sit together.
            Capsule()
                .fill(.background)
                .shadow(color: .black.opacity(0.18), radius: 1.5, y: 0.5)
                .frame(width: stopWidth, height: height - 3)
                .offset(x: knobOffset + 1.5, y: 0)
                .padding(.vertical, 1.5)
        }
        .clipShape(Capsule())
        .overlay(Capsule().strokeBorder(.quaternary, lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Appearance")
        .accessibilityValue(Self.title(for: theme))
    }

    private var knobOffset: CGFloat {
        CGFloat(Self.stops.firstIndex(of: theme) ?? 1) * stopWidth
    }

    /// Asset names, not SF Symbols: the icons are project SVGs, kept as vector data in the asset
    /// catalogue so they stay crisp at any size and tint with the label colour.
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
/// The list comes from `AppLanguage`, which is also what the settings screen and the language
/// controller read, so adding a language adds an entry here for free.
struct LanguagePicker: View {
    @Binding var language: String

    /// Called when a switch genuinely changes the override, so the caller can say a relaunch is
    /// needed rather than leaving a half-translated window unexplained.
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
                Text(option.pickerLabel).tag(option)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .frame(maxWidth: 190)
        .help("Language used by the app's own interface")
        .accessibilityLabel("Language")
        .accessibilityValue(AppLanguage(preference: language).pickerLabel)
    }
}

// MARK: - Both together

/// The pair as they sit in the main panel header: appearance, then language.
///
/// Grouped into one view so their placement is a layout decision rather than a rewrite.
struct AppearanceAndLanguageControls: View {
    @ObservedObject var preferencesStore: PreferencesStore

    @State private var relaunchNotice: AppLanguage?

    var body: some View {
        HStack(spacing: 10) {
            AppearanceSlider(theme: preferencesStore.binding(\.theme))
            LanguagePicker(
                language: preferencesStore.binding(\.language),
                onChangeRequiresRelaunch: { language in
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
            Text("Menus and system text change the next time the app is opened. Everything else keeps working in the meantime.")
        }
    }
}
