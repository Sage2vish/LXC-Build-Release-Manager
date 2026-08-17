import SwiftUI

/// Repository summary and build statistics.
///
/// Driven entirely by the repository plus its `RepositoryStats`, with the connection badge
/// passed in so the overview does not need to know how scanning works.
struct RepositoryOverviewView<StatusBadge: View>: View {
    let repository: Repository
    let stats: RepositoryStats
    @ViewBuilder let statusBadge: () -> StatusBadge

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Repository") {
                VStack(alignment: .leading, spacing: 6) {
                    LabeledContent("Name", value: repository.name)
                    LabeledContent("Path/URL", value: repository.source.displayPath)
                    LabeledContent("Connection") { statusBadge() }
                    LabeledContent("Total Builds", value: "\(stats.totalBuilds)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }

            HStack(spacing: 12) {
                statCard(title: "Total Builds", value: "\(stats.totalBuilds)")
                statCard(
                    title: "Success Rate",
                    value: stats.totalBuilds > 0 ? "\(Int(stats.successRate * 100))%" : "—"
                )
                statCard(
                    title: "Avg Duration",
                    value: stats.totalBuilds > 0
                        ? BuildPresentation.durationDescription(stats.averageDuration)
                        : "—"
                )
            }

            if let mostRecent = stats.mostRecent {
                Text("Most recently run: \(mostRecent.scriptLabel) — \(mostRecent.startedAt.relativeDescription)")
                    .font(.callout)
            }
            if let lastFailed = stats.lastFailed {
                Text("Last failed build: \(lastFailed.scriptLabel) — \(lastFailed.startedAt.relativeDescription)")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.weight(.semibold))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}
