import SwiftUI

/// The two window-level settings that live in the top bar: appearance and language.
///
/// They are **two separate controls**, not one widget with two halves — you can move, hide or
/// reposition either without touching the other. What they share is exactly one thing: the pill
/// they are drawn in, defined once in `ToolbarPill` so their heights cannot drift apart. Setting a
/// height on each independently is what let them disagree before: a `.menu` picker keeps its own
/// intrinsic height and quietly ignored the frame it was given.
///
/// Neither control introduces a setting. Each binds to the value Preferences already owns.

// MARK: - The shared pill

/// One definition of the toolbar control's shape, height and surface.
///
/// Both controls are built on it, so "the same height" is structural rather than two numbers that
/// happen to match today.
struct ToolbarPill<Content: View>: View {
    @ViewBuilder var content: () -> Content

    /// The height of every control in the top bar. One constant, one source.
    static var height: CGFloat { LayoutMetrics.toolbarControlHeight }

    var body: some View {
        content()
            .frame(height: Self.height)
            .background(Capsule().fill(.quaternary.opacity(0.55)))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(.quaternary, lineWidth: 0.5))
            // Fixed vertically only: the pill owns its height, its content owns its width.
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Appearance

/// A three-stop slider: Bright · Default · Dark.
///
/// Built rather than borrowed from `Picker(.segmented)` because the requested behaviour is a
/// slider — one knob travelling between three stops — and a segmented picker cannot show a knob
/// move. Default sits in the middle: it is the resting position, with an override either side.
struct AppearanceSlider: View {
    @Binding var theme: AppTheme

    private static let stops: [AppTheme] = [.light, .system, .dark]
    private var stopWidth: CGFloat { LayoutMetrics.appearanceStopWidth }

    var body: some View {
        ToolbarPill {
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
                            .frame(width: stopWidth, height: ToolbarPill<EmptyView>.height)
                            .foregroundStyle(theme == stop ? Color.primary : Color.secondary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(Self.help(for: stop))
                    .accessibilityLabel(Self.title(for: stop))
                    .accessibilityAddTraits(theme == stop ? [.isSelected] : [])
                }
            }
            .background(alignment: .leading) {
                // The knob: one shape that travels, so this reads as a slider rather than three
                // buttons that happen to sit together.
                Capsule()
                    .fill(.background)
                    .shadow(color: .black.opacity(0.18), radius: 1.5, y: 0.5)
                    .frame(width: stopWidth, height: ToolbarPill<EmptyView>.height - 4)
                    .offset(x: knobOffset)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Appearance")
        .accessibilityValue(Self.title(for: theme))
    }

    private var knobOffset: CGFloat {
        CGFloat(Self.stops.firstIndex(of: theme) ?? 1) * stopWidth
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
/// A `Menu` rather than a `Picker`: a `.menu` picker draws its own control chrome at its own
/// height, which is precisely why the two toolbar controls did not match. This puts the same pill
/// around a plain label, so both controls are the same height by construction.
struct LanguagePicker: View {
    @Binding var language: String

    /// Called when a switch genuinely changes the override, so the caller can say a relaunch is
    /// needed rather than leaving a half-translated window unexplained.
    var onChangeRequiresRelaunch: (AppLanguage) -> Void = { _ in }

    private var current: AppLanguage { AppLanguage(preference: language) }

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { option in
                Button {
                    guard option != current else { return }
                    language = option.rawValue
                    onChangeRequiresRelaunch(option)
                } label: {
                    // A tick beside the active language, because a menu that closes without
                    // confirming what is selected leaves you guessing.
                    if option == current {
                        Label(option.pickerLabel, systemImage: "checkmark")
                    } else {
                        Text(option.pickerLabel)
                    }
                }
            }
        } label: {
            ToolbarPill {
                HStack(spacing: 5) {
                    Image(systemName: "globe")
                        .font(.system(size: 11, weight: .medium))
                    // The short name in the bar; the full "English — native" pairing is in the
                    // menu, where there is room for it.
                    Text(current.nativeName)
                        .font(.system(size: 11, weight: .medium))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .foregroundStyle(Color.primary)
            }
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Language used by the app's own interface")
        .accessibilityLabel("Language")
        .accessibilityValue(current.pickerLabel)
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
