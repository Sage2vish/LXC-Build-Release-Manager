import SwiftUI

/// Build history for one repository.
///
/// Takes records and a selection callback rather than reaching for the history store, so it can
/// be previewed and reused without the whole repository workspace behind it.
struct RepositoryHistoryView: View {
    let records: [BuildRecord]
    /// Called with the record the user picked, so the caller can switch to the Logs tab.
    let onSelectRecord: (BuildRecord) -> Void

    var body: some View {
        GroupBox("Build History") {
            if records.isEmpty {
                Text("No builds run yet for this repository.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(records) { record in
                        Button {
                            onSelectRecord(record)
                        } label: {
                            row(for: record)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(record.scriptLabel), \(record.status.rawValue)")
                        .accessibilityHint("Opens this run's log.")
                    }
                }
            }
        }
    }

    private func row(for record: BuildRecord) -> some View {
        HStack {
            Image(systemName: BuildPresentation.symbolName(for: record.status))
                .foregroundStyle(BuildPresentation.color(for: record.status))
            VStack(alignment: .leading, spacing: 2) {
                Text(record.scriptLabel).font(.body.weight(.medium))
                Text(record.startedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(BuildPresentation.durationDescription(record.durationSeconds))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
    }
}
