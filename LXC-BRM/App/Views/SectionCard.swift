import SwiftUI

/// The one card surface used by the main panel's sections.
///
/// Available Build Scripts and Live Output had drifted apart — one was a `GroupBox` with a
/// blue/pink gradient, the other carried its own `.thinMaterial` background that fought the card
/// wrapped around it. Defining the surface once means they cannot diverge again.
struct SectionCard: ViewModifier {
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.sectionSurface, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.sectionBorder, lineWidth: 1)
            )
    }
}

extension View {
    /// Wraps a main-panel section in the shared card surface.
    func sectionCard(cornerRadius: CGFloat = 12) -> some View {
        modifier(SectionCard(cornerRadius: cornerRadius))
    }
}

extension Color {
    /// Neutral grey that reads as a raised surface in light mode and a recessed one in dark,
    /// rather than a tint that competes with the accent colour.
    static var sectionSurface: Color {
        Color(nsColor: .controlBackgroundColor).opacity(0.55)
    }

    static var sectionBorder: Color {
        Color(nsColor: .separatorColor)
    }
}
