import SwiftUI

struct RecentRepositoryRow: View {
    let repository: Repository
    @ObservedObject var store: RepositoryStore

    var body: some View {
        Button {
            store.select(repository)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: repository.source.isLocal ? "folder" : "chevron.left.forwardslash.chevron.right")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(repository.name).font(.subheadline)
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
