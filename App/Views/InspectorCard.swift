import SwiftUI

/// The one card used by the Detail View panel.
///
/// The five cards had drifted into three different shapes: Selected Script put its title inside as
/// a caption, Build Parameters put its title inside as a headline, and Build Status and Quick
/// Actions used the `GroupBox` label while Build History had no title at all. Three treatments in
/// one column read as three unrelated widgets rather than one panel.
///
/// This settles it: every card is a titled **ribbon** over its content, so a card is separable at
/// a glance and every card separates the same way. The ribbon is tinted rather than plain, because
/// the panel sits on a translucent material where a border alone does not hold the eye.
struct InspectorCard<Content: View, Accessory: View>: View {
    let title: LocalizedStringKey
    /// A detail about what the card is showing — a script filename, a count.
    ///
    /// Rendered as the first line **inside** the box rather than in the ribbon. The ribbon names
    /// the section and nothing else; a filename sitting in it made the label two things at once
    /// and pushed the title off its own line.
    var subtitle: String?
    /// Optional trailing control in the ribbon: a spinner, a "View All" button.
    @ViewBuilder var accessory: () -> Accessory
    @ViewBuilder var content: () -> Content

    /// Every section is a **rounded box**.
    ///
    /// The label keeps its square bottom edge — it is a header band across the top of the box, not
    /// a floating tab — but its top corners follow the box's radius so the tint reaches the corner
    /// instead of leaving two square shoulders inside a rounded card.
    private let cornerRadius = LayoutMetrics.inspectorCardCornerRadius

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius)
    }

    private var labelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: cornerRadius,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: 0,
            topTrailingRadius: cornerRadius
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ribbon
            VStack(alignment: .leading, spacing: 8) {
                if let subtitle {
                    Text(subtitle)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
        }
        .background(Color.inspectorCardSurface, in: cardShape)
        .overlay(cardShape.stroke(Color.sectionBorder, lineWidth: 1))
        .clipShape(cardShape)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(title))
    }

    private var ribbon: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .textCase(.uppercase)
                .kerning(0.4)
            Spacer(minLength: 8)
            accessory()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        // Only this shape is rounded, and only along its top edge.
        .background(labelShape.fill(Color.inspectorRibbon))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.sectionBorder)
                .frame(height: 1)
        }
    }
}

extension InspectorCard where Accessory == EmptyView {
    init(
        title: LocalizedStringKey,
        subtitle: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(title: title, subtitle: subtitle, accessory: { EmptyView() }, content: content)
    }
}

extension Color {
    /// The card surface in the Detail View panel: brighter and matte, rather than the translucent
    /// material the panel used to carry. A panel that shows the desktop through it competes with
    /// the content it is describing; a flat, light surface does not.
    static var inspectorCardSurface: Color {
        Color(nsColor: .controlBackgroundColor).opacity(0.92)
    }

    /// The ribbon tint.
    ///
    /// Derived from the accent colour rather than fixed, so the panel follows the Appearance
    /// preference instead of holding one hard-coded blue — but faint enough that five stacked
    /// ribbons do not turn the column into a colour chart.
    static var inspectorRibbon: Color {
        Color.accentColor.opacity(0.12)
    }
}

extension Color {
    /// The Detail View panel's own background, behind the stacked cards.
    ///
    /// Deliberately a shade darker than the cards so the seams between sections stay visible when
    /// several cards sit against each other.
    static var inspectorPanelSurface: Color {
        Color(nsColor: .windowBackgroundColor)
    }
}
