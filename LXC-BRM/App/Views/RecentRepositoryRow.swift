import SwiftUI

struct RecentRepositoryRow: View {
    let repository: Repository
    @ObservedObject var store: RepositoryStore
    var showsPath: Bool = true

    var body: some View {
        Button {
            store.select(repository)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: repository.source.isLocal ? "folder" : "chevron.left.forwardslash.chevron.right")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(repository.name).font(.subheadline)
                    if showsPath {
                        Text(repository.source.displayPath)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    // "Last accessed" is independent of the path toggle.
                    Text("Opened \(repository.lastAccessed.relativeDescription)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
