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

/// The window's background image, drawn behind every region.
///
/// Loaded once and held, because decoding a 1536×1024 PNG on every layout pass would be a real
/// cost. Honours **Reduce transparency**, and stays visible in dark mode with a stronger overlay
/// so the image still reads as the app's identity without washing out the content.
struct AppBackground: View {
    let preferences: Preferences
    @Environment(\.colorScheme) private var colorScheme

    static func imageURL(in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: "ui-back-main", withExtension: "png", subdirectory: "Assets")
        ?? bundle.url(forResource: "ui-back-main", withExtension: "png")
    }

    private static let image: NSImage? = imageURL().flatMap { NSImage(contentsOf: $0) }

    static func displayState(preferences: Preferences, colorScheme: ColorScheme) -> DisplayState {
        DisplayState(
            shouldShow: !preferences.reduceTransparency,
            backgroundOpacity: colorScheme == .dark ? 0.18 : 0.0,
            imageOpacity: colorScheme == .dark ? 0.36 : 0.86,
            overlayOpacity: colorScheme == .dark ? 0.26 : 0.0
        )
    }

    var body: some View {
        let displayState = Self.displayState(preferences: preferences, colorScheme: colorScheme)
        ZStack {
            if displayState.shouldShow {
                Color(nsColor: .windowBackgroundColor).opacity(displayState.backgroundOpacity)
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
            if displayState.shouldShow, let image = Self.image {
                Image(nsImage: image)
                    .resizable()
                    // Fill rather than stretch: the window will not match the asset's 3:2.
                    .aspectRatio(contentMode: .fill)
                    .opacity(displayState.imageOpacity)
                    .overlay(Color.black.opacity(displayState.overlayOpacity))
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    struct DisplayState: Equatable {
        let shouldShow: Bool
        let backgroundOpacity: Double
        let imageOpacity: Double
        let overlayOpacity: Double
    }
}
