import SwiftUI

/// Turns the appearance preferences into concrete SwiftUI values.
///
/// These fields were stored and rendered in the settings screen but nothing read them, so the
/// toggles did nothing. Deriving them here keeps the mapping in one testable place instead of
/// scattering `if preferences.x` checks through the views.
enum AppearanceSettings {
    /// Multiplier applied to the app's text. Clamped to the range the settings stepper offers,
    /// so a hand-edited `preferences.json` cannot render the UI unusable.
    static func textScale(_ preferences: Preferences) -> CGFloat {
        let percent = min(max(preferences.textSizePercent, 80), 150)
        return CGFloat(percent) / 100
    }

    /// Vertical padding for list rows and cards.
    static func rowSpacing(_ preferences: Preferences) -> CGFloat {
        switch preferences.uiDensity {
        case "Compact": return 4
        case "Spacious": return 14
        default: return 8   // Comfortable
        }
    }

    static func cornerRadius(_ preferences: Preferences) -> CGFloat {
        preferences.roundWindowCorners ? 12 : 0
    }

    /// `nil` means "use the system accent", which is what an unparseable value falls back to.
    static func accentColor(_ preferences: Preferences) -> Color? {
        color(fromHex: preferences.accentColorHex)
    }

    /// Sidebar background: a flat material when the user asks to reduce transparency.
    static func sidebarMaterial(_ preferences: Preferences) -> Material {
        preferences.reduceTransparency ? .thick : .ultraThin
    }

    /// Animation to use for state changes, or `nil` when the user has turned animations off.
    /// Also respects the system Reduce Motion setting.
    static func animation(_ preferences: Preferences, reduceMotion: Bool = false) -> Animation? {
        (preferences.showAnimations && !reduceMotion) ? .default : nil
    }

    /// Parses `#RRGGBB` / `RRGGBB` / `#RRGGBBAA`. Returns `nil` for anything else.
    static func color(fromHex hex: String) -> Color? {
        var value = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6 || value.count == 8,
              value.allSatisfy({ $0.isHexDigit }),
              let number = UInt64(value, radix: 16) else {
            return nil
        }

        let red, green, blue, alpha: Double
        if value.count == 6 {
            red = Double((number & 0xFF0000) >> 16) / 255
            green = Double((number & 0x00FF00) >> 8) / 255
            blue = Double(number & 0x0000FF) / 255
            alpha = 1
        } else {
            red = Double((number & 0xFF00_0000) >> 24) / 255
            green = Double((number & 0x00FF_0000) >> 16) / 255
            blue = Double((number & 0x0000_FF00) >> 8) / 255
            alpha = Double(number & 0x0000_00FF) / 255
        }
        return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

private struct AppTextScaleKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1
}

private struct AppRowSpacingKey: EnvironmentKey {
    static let defaultValue: CGFloat = 8
}

extension EnvironmentValues {
    /// Multiplier from the "Text Size (%)" preference.
    var appTextScale: CGFloat {
        get { self[AppTextScaleKey.self] }
        set { self[AppTextScaleKey.self] = newValue }
    }

    /// Row padding derived from the "UI density" preference.
    var appRowSpacing: CGFloat {
        get { self[AppRowSpacingKey.self] }
        set { self[AppRowSpacingKey.self] = newValue }
    }
}
