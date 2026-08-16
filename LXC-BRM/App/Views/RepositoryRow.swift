import SwiftUI

struct RepositoryRow: View {
    let repository: Repository
    @ObservedObject var store: RepositoryStore

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: repository.source.isLocal ? "folder" : "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(.secondary)
                    Text(repository.name)
                        .font(.headline)
                }
                Text(repository.source.displayPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
                .help("Remove from list")
            }
        }
        .padding(.vertical, 4)
    }
}

extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
