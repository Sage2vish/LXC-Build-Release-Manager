import SwiftUI

struct RepositoryRow: View {
    let repository: Repository
    @ObservedObject var store: RepositoryStore
    /// The name always shows; only the path is optional.
    var showsPath: Bool = true

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: repository.source.isLocal ? "folder" : "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(.secondary)
                    Text(repository.name)
                        .font(.headline)
                }
                if showsPath {
                    Text(repository.source.displayPath)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Text("Last accessed \(repository.lastAccessed.relativeDescription)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 4)
            VStack(spacing: 6) {
                Button {
                    store.togglePin(repository)
                } label: {
                    Image(systemName: repository.isPinned ? "pin.fill" : "pin")
                }
                .buttonStyle(.borderless)
                .help(repository.isPinned ? "Unpin" : "Pin")

                Button {
                    store.remove(repository)
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Remove from List")
            }
        }
        .padding(.vertical, 4)
    }
}

/// The rounded box the sidebar's rows sit in — drawn one row at a time.
///
/// The sidebar is a `List`, and a `List` gives no way to draw a box around a section. So the box is
/// drawn *by its rows*: every row paints the container's left and right sides, the first row paints
/// the top and rounds its corners, the last paints the bottom and rounds its, and every row but the
/// last draws the hairline that separates it from the next. From the outside it reads as one
/// rounded rectangle with rules across it — which is what it is — and the list keeps its selection,
/// its keyboard navigation and its scrolling, all of which a hand-built stack of rows would have
/// thrown away.
struct ListBoxRowBackground: View {
    /// Where this row sits in its group, which decides which edges of the box it is responsible
    /// for. A group of one row draws the whole box itself.
    enum Position {
        case first, middle, last, only

        var isFirst: Bool { self == .first || self == .only }
        var isLast: Bool { self == .last || self == .only }
    }

    let position: Position
    var isSelected: Bool = false

    /// Small enough to read as a container rather than as a pill, and shared by the fill and the
    /// border so the two cannot drift apart.
    static let cornerRadius: CGFloat = 8


    /// The box's margin from the panel's edges. Applied here rather than by the row, because a
    /// list row's background fills the whole row — insets set on the row move its *content*, not
    /// the surface behind it, so a box drawn without this runs off both sides of the panel.
    private static let horizontalInset: CGFloat = 8

    var body: some View {
        boxBody.padding(.horizontal, Self.horizontalInset)
    }

    private var boxBody: some View {
        shape
            .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.03))
            .overlay { ListBoxBorder(position: position).stroke(Color.sectionBorder, lineWidth: 1) }
            .overlay(alignment: .bottom) {
                if !position.isLast {
                    // Border to border. Inset at one end only, the rule stopped short of the left
                    // side and ran into the right one, which reads as a mistake rather than as a
                    // margin.
                    Rectangle()
                        .fill(Color.sectionBorder)
                        .frame(height: 1)
                }
            }
    }

    /// `.circular` is stated rather than defaulted. `UnevenRoundedRectangle` uses `.continuous`
    /// when no style is given, and the border beside it is an open path built from circular arcs —
    /// two different curves at the same nominal radius, which is a corner that can never line up.
    /// Both are circular now, so the fill and its outline share one geometry.
    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: position.isFirst ? Self.cornerRadius : 0,
            bottomLeadingRadius: position.isLast ? Self.cornerRadius : 0,
            bottomTrailingRadius: position.isLast ? Self.cornerRadius : 0,
            topTrailingRadius: position.isFirst ? Self.cornerRadius : 0,
            style: .circular
        )
    }
}

/// The part of the box's outline that belongs to one row.
///
/// Deliberately an open path rather than a rounded rectangle: stroking a closed shape per row would
/// draw a line across the top and bottom of every row, and the box would come out looking like a
/// stack of separate boxes. Each row draws its two sides, and only the end rows close the box.
struct ListBoxBorder: Shape {
    let position: ListBoxRowBackground.Position

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(ListBoxRowBackground.cornerRadius, rect.height / 2)

        // Where this row's straight sides stop. A row that owns the bottom corners has to hand the
        // last `radius` of each side over to the curve: running the side all the way to `maxY` drew
        // a square corner straight over the rounded one, which is what made the box read as barely
        // rounded at all.
        let sideBottom = position.isLast ? rect.maxY - radius : rect.maxY

        path.move(to: CGPoint(x: rect.minX, y: sideBottom))

        if position.isFirst {
            // Leading side, both top corners, and back down the trailing side, in one run.
            // `addArc(tangent1End:tangent2End:radius:)` is a true circular arc, so it matches the
            // `.circular` fill underneath exactly — a quadratic curve through the corner sits
            // noticeably inside that arc and leaves a sliver of fill outside the stroke.
            path.addArc(
                tangent1End: CGPoint(x: rect.minX, y: rect.minY),
                tangent2End: CGPoint(x: rect.maxX, y: rect.minY),
                radius: radius
            )
            path.addArc(
                tangent1End: CGPoint(x: rect.maxX, y: rect.minY),
                tangent2End: CGPoint(x: rect.maxX, y: rect.maxY),
                radius: radius
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: sideBottom))
        } else {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: sideBottom))
        }

        if position.isLast {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
            path.addArc(
                tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                tangent2End: CGPoint(x: rect.maxX, y: rect.maxY),
                radius: radius
            )
            path.addArc(
                tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                tangent2End: CGPoint(x: rect.maxX, y: rect.maxY - radius),
                radius: radius
            )
        }

        return path
    }
}

extension ListBoxRowBackground.Position {
    /// Where a row sits in a group of `count` rows.
    init(index: Int, count: Int) {
        if count <= 1 {
            self = .only
        } else if index == 0 {
            self = .first
        } else if index == count - 1 {
            self = .last
        } else {
            self = .middle
        }
    }
}
