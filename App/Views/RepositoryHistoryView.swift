import SwiftUI

/// Build history for one repository.
///
/// Takes records and callbacks rather than reaching for the history store, so it can be previewed
/// and reused without the whole repository workspace behind it.
struct RepositoryHistoryView: View {
    let records: [BuildRecord]
    /// Called with the record the user picked, so the caller can switch to the Logs tab.
    let onSelectRecord: (BuildRecord) -> Void
    /// Called when the user confirms clearing this repository's history. Omitted by callers that
    /// have nothing to clear against, in which case the control is not offered at all.
    var onClearHistory: (() -> Void)?
    /// Whether to ask before clearing, from the "Confirm before clearing history or logs"
    /// preference. Defaults to asking: the safer reading of a missing value.
    var confirmBeforeClearing = true

    @State private var outcome: HistoryFilter.Outcome = .all
    @State private var script = HistoryFilter.allScripts
    @State private var isConfirmingClear = false

    private var filtered: [BuildRecord] {
        HistoryFilter.apply(records, outcome: outcome, script: script)
    }

    var body: some View {
        GroupBox("Build History") {
            if records.isEmpty {
                Text("No builds run yet for this repository.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    controls
                    if filtered.isEmpty {
                        // Deliberately different wording from the empty state above: "nothing
                        // ran" and "nothing matches" are different facts about the repository.
                        Text("No runs match these filters.")
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(filtered) { record in
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
                    if let summary = HistoryFilter.summary(shown: filtered.count, total: records.count) {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .confirmationDialog(
            "Clear this repository's build history?",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) { onClearHistory?() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Removes \(records.count) recorded runs for this repository. Log files on disk are not deleted, and no other repository is affected.")
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Picker("", selection: $outcome) {
                ForEach(HistoryFilter.Outcome.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 320)
            .accessibilityLabel("Filter by outcome")

            Picker("", selection: $script) {
                Text(HistoryFilter.allScripts).tag(HistoryFilter.allScripts)
                Divider()
                ForEach(HistoryFilter.scriptLabels(in: records), id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
            .frame(maxWidth: 200)
            .accessibilityLabel("Filter by script")

            Spacer()

            if onClearHistory != nil {
                Button("Clear History", role: .destructive) {
                    if confirmBeforeClearing {
                        isConfirmingClear = true
                    } else {
                        onClearHistory?()
                    }
                }
                .help("Removes this repository's recorded runs. Log files on disk are kept.")
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
