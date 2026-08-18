import SwiftUI

/// Repository summary and build statistics.
///
/// Driven by the repository plus its records, with the connection badge passed in so the overview
/// does not need to know how scanning works.
struct RepositoryOverviewView<StatusBadge: View>: View {
    let repository: Repository
    /// Every recorded run, newest first. Statistics are computed here rather than handed in, so
    /// the date range can change without a round trip through the store.
    let records: [BuildRecord]
    @ViewBuilder let statusBadge: () -> StatusBadge

    @State private var range: StatsRange = .allTime

    private var scopedRecords: [BuildRecord] { range.filter(records) }
    private var stats: RepositoryStats { RepositoryStats.make(from: scopedRecords) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Repository").font(.headline)
                LabeledContent("Name", value: repository.name)
                LabeledContent("Path/URL", value: repository.source.displayPath)
                LabeledContent("Connection") { statusBadge() }
                LabeledContent("Total Builds", value: "\(records.count)")
            }
            .sectionCard()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Statistics").font(.headline)
                    Spacer()
                    Picker("", selection: $range) {
                        ForEach(StatsRange.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 150)
                    .accessibilityLabel("Statistics date range")
                }

                // Said plainly, because a success rate over 7 days and one over all time are
                // different claims and the numbers alone do not say which is on screen.
                Text(rangeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

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
            .sectionCard()
        }
    }

    private var rangeDescription: String {
        switch range {
        case .allTime:
            return "Every run ever recorded for this repository."
        default:
            let hidden = records.count - scopedRecords.count
            let scope = "\(range.rawValue.lowercased()) — \(scopedRecords.count) of \(records.count) runs"
            return hidden == 0 ? "\(scope). Nothing older exists." : "\(scope)."
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
