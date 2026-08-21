import CoreGraphics

/// Every layout number the window's three columns depend on, named once.
///
/// The columns used to be sized in fixed points — 180/ideal/420 for the sidebar, 240/340/900 for
/// the inspector — which meant they were the same physical width on a 13-inch laptop and a 32-inch
/// display: the sidebar swallowed a small screen and looked lost on a large one.
///
/// They are **fractions of the window** instead, and every value below is a named default rather
/// than a number buried in a view, so a proportion can be changed in one place and reviewed as a
/// decision.
enum LayoutMetrics {

    // MARK: Column proportions

    /// The repository sidebar: **20%** of the window.
    static let sidebarWidthFraction: CGFloat = 0.20

    /// The Detail View panel: **15%** of the window.
    static let inspectorWidthFraction: CGFloat = 0.15

    /// The centre column takes everything the other two do not — **65%** with both open, and all
    /// of it when they are hidden. It is never given a width of its own; it is the remainder, which
    /// is why hiding a panel widens the work area instead of leaving a gap.
    static var centreWidthFraction: CGFloat { 1 - sidebarWidthFraction - inspectorWidthFraction }

    // MARK: Clamps

    /// How far a column may be dragged from its proportion, as a fraction of the window.
    ///
    /// A proportion sets where a column *starts*; these keep dragging sane at both extremes.
    static let sidebarMinFraction: CGFloat = 0.12
    static let sidebarMaxFraction: CGFloat = 0.34
    static let inspectorMinFraction: CGFloat = 0.10
    static let inspectorMaxFraction: CGFloat = 0.32

    /// Absolute floors in points, because a percentage of a very small window is still unusable:
    /// the sidebar has to fit a repository name and its footer buttons, and the inspector has to
    /// fit a parameter control.
    static let sidebarFloor: CGFloat = 150
    static let inspectorFloor: CGFloat = 170

    /// The width assumed before the window has reported one — only used for the first layout pass.
    static let assumedWindowWidth: CGFloat = 1_400

    // MARK: Derived widths

    /// Resolves a fraction against the window width, never returning less than `floor`.
    static func width(
        of fraction: CGFloat,
        in windowWidth: CGFloat,
        floor: CGFloat
    ) -> CGFloat {
        let usable = windowWidth > 0 ? windowWidth : assumedWindowWidth
        return Swift.max(floor, usable * fraction)
    }

    /// Why `ideal` is seeded once and never recomputed.
    ///
    /// `navigationSplitViewColumnWidth(min:ideal:max:)` and `inspectorColumnWidth(...)` treat
    /// `ideal` as the width the column *wants*. Handing them a freshly computed ideal on every
    /// layout pass re-pins the column, so a drag springs straight back and the panel feels stuck.
    /// The proportion decides where a column **starts**; after that the user's drag owns it, and
    /// only the min/max clamps still apply.

    /// min / ideal / max for the sidebar column at this window width.
    static func sidebarColumn(for windowWidth: CGFloat) -> (min: CGFloat, ideal: CGFloat, max: CGFloat) {
        (
            width(of: sidebarMinFraction, in: windowWidth, floor: sidebarFloor),
            width(of: sidebarWidthFraction, in: windowWidth, floor: sidebarFloor),
            width(of: sidebarMaxFraction, in: windowWidth, floor: sidebarFloor + 120)
        )
    }

    /// min / ideal / max for the Detail View panel at this window width.
    static func inspectorColumn(for windowWidth: CGFloat) -> (min: CGFloat, ideal: CGFloat, max: CGFloat) {
        (
            width(of: inspectorMinFraction, in: windowWidth, floor: inspectorFloor),
            width(of: inspectorWidthFraction, in: windowWidth, floor: inspectorFloor),
            width(of: inspectorMaxFraction, in: windowWidth, floor: inspectorFloor + 120)
        )
    }

    // MARK: Detail View panel

    // MARK: Status bar

    /// The height of the bottom status strip.
    ///
    /// Named here because three places need to agree on it: the strip draws itself this tall, and
    /// the sidebar and the centre column each reserve exactly this much at their bottom so the
    /// glass never covers a control. The right panel deliberately does **not** reserve it — it runs
    /// past the strip to the bottom of the window, which is the whole point of the strip stopping
    /// at the panel's edge.
    static let statusBarHeight: CGFloat = 33

    // MARK: Top bar

    /// The height of every control in the window's top bar.
    ///
    /// Named once so the appearance slider and the language control cannot disagree: they are
    /// separate controls, and the only thing they share is this number and the pill drawn from it.
    static let toolbarControlHeight: CGFloat = 24

    /// The width of one stop on the appearance slider.
    static let appearanceStopWidth: CGFloat = 34

    /// The corner radius of a Detail View card. Each section is a rounded box, and its label
    /// carries the same radius across its top so the tint reaches the corner rather than leaving
    /// two square shoulders inside a rounded box.
    static let inspectorCardCornerRadius: CGFloat = 10

    /// The gap between cards, and between the cards and the panel edge. Rounded boxes need it:
    /// butted against each other they stop reading as separate sections.
    static let inspectorCardGap: CGFloat = 10

    // MARK: Centre column spacing

    /// Space either side of the centre column's cards — between them and the left sidebar, and
    /// between them and the Detail View panel.
    ///
    /// Reduced by 60% from the original 24pt: the cards were floating in a moat while the table
    /// inside them was running out of room for its own columns.
    static let centreHorizontalPadding: CGFloat = 10

    /// Space above and below the centre column's cards. 60% off the original 12pt.
    static let centreVerticalPadding: CGFloat = 5

    /// The gap either side of the Build tab's draggable divider. 60% off the original 6pt, which
    /// keeps the divider grabbable without pushing the two cards apart.
    static let centreSplitGap: CGFloat = 2
}
