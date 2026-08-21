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

    /// How far the hairline between rows is inset, so it reads as a rule inside the box rather than
    /// as the box being cut in half.
    private static let separatorInset: CGFloat = 10

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
                    Rectangle()
                        .fill(Color.sectionBorder)
                        .frame(height: 1)
                        .padding(.leading, Self.separatorInset)
                }
            }
    }

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: position.isFirst ? Self.cornerRadius : 0,
            bottomLeadingRadius: position.isLast ? Self.cornerRadius : 0,
            bottomTrailingRadius: position.isLast ? Self.cornerRadius : 0,
            topTrailingRadius: position.isFirst ? Self.cornerRadius : 0
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

        if position.isFirst {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }

        if position.isLast {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.maxY),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY - radius),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
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
