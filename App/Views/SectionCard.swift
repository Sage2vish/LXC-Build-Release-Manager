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

/// The app's glass, in one place.
///
/// Three surfaces are made of it — the bar across the top of the window, the status strip across
/// the bottom, and the right panel — and they have to be the same material or the window reads as
/// three separate ideas. Each is a translucent base with a soft smear of light drawn over it and,
/// where it meets content, a lit hairline along that edge.
///
/// The smudge is the point. Flat material reads as another opaque panel butted against the rest;
/// the smear of light is what makes it read as glass laid over the window.
///
/// With **Reduce transparency** on there is no glass to smudge: it falls back to the window's own
/// surface, keeping the hairline so the surface still has an edge.
struct GlassSurface: View {
    /// The edge that faces content, and therefore carries the hairline. `nil` for a surface whose
    /// edge is drawn by whatever contains it.
    enum Hairline {
        case top, bottom, leading, trailing
    }

    let material: Material
    let hairline: Hairline?
    let reduceTransparency: Bool

    init(_ material: Material = .ultraThin, hairline: Hairline? = nil, reduceTransparency: Bool) {
        self.material = material
        self.hairline = hairline
        self.reduceTransparency = reduceTransparency
    }

    var body: some View {
        ZStack {
            if reduceTransparency {
                Color(nsColor: .windowBackgroundColor)
            } else {
                Rectangle().fill(material)
                smudge
            }
        }
        .overlay(alignment: hairlineAlignment) { hairlineRule }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Two soft pools of light and a diagonal wash. Every size is a fraction of the surface, so the
    /// same smudge works on a 33-point strip and on a column the height of the window, and both are
    /// blurred well past their own edges — a smudge has no outline.
    private var smudge: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.20),
                        Color.white.opacity(0.05),
                        Color.black.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Ellipse()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: proxy.size.width * 0.55, height: proxy.size.height * 0.80)
                    .blur(radius: 30)
                    .offset(x: -proxy.size.width * 0.10, y: -proxy.size.height * 0.25)

                Ellipse()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: proxy.size.width * 0.40, height: proxy.size.height * 0.60)
                    .blur(radius: 34)
                    .offset(x: proxy.size.width * 0.55, y: proxy.size.height * 0.35)
            }
            .blendMode(.softLight)
        }
    }

    private var hairlineAlignment: Alignment {
        switch hairline {
        case .top: return .top
        case .bottom: return .bottom
        case .leading: return .leading
        case .trailing: return .trailing
        case nil: return .center
        }
    }

    /// A separator with a thin highlight on the content side of it, so the glass has a lit edge
    /// rather than simply stopping.
    @ViewBuilder
    private var hairlineRule: some View {
        switch hairline {
        case .top:
            VStack(spacing: 0) {
                separator(width: nil, height: 1)
                highlight(width: nil, height: 1)
            }
        case .bottom:
            VStack(spacing: 0) {
                highlight(width: nil, height: 1)
                separator(width: nil, height: 1)
            }
        case .leading:
            HStack(spacing: 0) {
                separator(width: 1, height: nil)
                highlight(width: 1, height: nil)
            }
        case .trailing:
            HStack(spacing: 0) {
                highlight(width: 1, height: nil)
                separator(width: 1, height: nil)
            }
        case nil:
            EmptyView()
        }
    }

    private func separator(width: CGFloat?, height: CGFloat?) -> some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(width: width, height: height)
    }

    private func highlight(width: CGFloat?, height: CGFloat?) -> some View {
        Rectangle()
            .fill(Color.white.opacity(reduceTransparency ? 0 : 0.35))
            .frame(width: width, height: height)
            .blendMode(.plusLighter)
    }
}

/// The strip of window level with the title bar, painted by the app.
///
/// macOS draws the toolbar's background across the whole window; it cannot be told to stop at a
/// column. So it is hidden, and this stands in for it, one segment per column: the sidebar's glass
/// on the left, the bar itself over the centre, and the right panel's glass on the right, each
/// carrying its own edge hairline up through the strip.
///
/// The result is the arrangement a Mac window has — two columns running the full height of the
/// window, and a bar that belongs to the middle, beginning where the sidebar ends and ending where
/// the panel begins. The status strip follows the same rule along the bottom.
///
/// The toolbar's buttons are unaffected — macOS still draws them on top. Only the background moved.
struct WindowTopChrome: View {
    /// The title bar's height, measured once from the window. `0` until that measurement lands, at
    /// which point the safe area is used instead — whichever of the two actually knows.
    let height: CGFloat
    /// The live width of the left sidebar, or `0` when it is hidden. The sidebar's own glass
    /// continues up through this strip, which is what makes it a column and not a panel that starts
    /// under the title bar.
    let sidebarWidth: CGFloat
    /// The live width of the right panel, or `0` when it is hidden — in which case the bar simply
    /// runs to the window's right edge.
    let panelWidth: CGFloat
    let reduceTransparency: Bool

    var body: some View {
        // Drawn under the safe area, and measuring it from there: a view that has expanded past the
        // safe area is told how far in the safe area starts, which is exactly the height of the
        // title bar. Asking AppKit for the same number means reading a window mid-layout and
        // feeding the answer back into it, which is a loop the window never survives.
        GeometryReader { proxy in
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    if sidebarWidth > 0 {
                        GlassSurface(.ultraThin, hairline: .trailing, reduceTransparency: reduceTransparency)
                            .frame(width: sidebarWidth)
                    }

                    GlassSurface(.ultraThin, hairline: .bottom, reduceTransparency: reduceTransparency)

                    if panelWidth > 0 {
                        GlassSurface(.regular, hairline: .leading, reduceTransparency: reduceTransparency)
                            .frame(width: panelWidth)
                    }
                }
                .frame(height: max(height, proxy.safeAreaInsets.top))

                Spacer(minLength: 0)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
