import Foundation
import SwiftUI

/// Shared display rules for build status, durations, and relative dates.
///
/// These were private helpers duplicated across `ContentView`, the sidebar rows, and the
/// inspector, so the same status could be formatted differently depending on which view drew
/// it. Named here once and testable without a view.
enum BuildPresentation {
    static func symbolName(for status: BuildStatus) -> String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "slash.circle.fill"
        case .running: return "circle.dotted"
        }
    }

    static func color(for status: BuildStatus) -> Color {
        switch status {
        case .success: return .green
        case .failed: return .red
        case .cancelled: return .orange
        case .running: return .blue
        }
    }

    /// Compact tick/cross used inline in the scripts table.
    static func glyph(for status: BuildStatus) -> String {
        switch status {
        case .success: return "✓"
        case .cancelled: return "⊘"
        case .failed: return "✗"
        case .running: return "…"
        }
    }

    /// `90` -> `"1m 30s"`, `45` -> `"45s"`. Negative input is clamped to zero rather than
    /// rendering something like `-1m -30s`.
    static func durationDescription(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let minutes = total / 60
        let remainder = total % 60
        return minutes > 0 ? "\(minutes)m \(remainder)s" : "\(remainder)s"
    }
}

extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
