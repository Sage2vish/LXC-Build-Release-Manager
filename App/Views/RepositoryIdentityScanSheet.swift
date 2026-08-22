import SwiftUI

struct RepositoryIdentityScanSheet: View {
    let repository: Repository
    let preferences: Preferences
    let additionalScriptPaths: [String]
    let forceRescan: Bool
    @ObservedObject var scanStore: RepositoryIdentityScanStore
    let onClose: () -> Void

    @State private var result: RepositoryIdentityScanResult
    @State private var task: Task<Void, Never>?

    init(
        repository: Repository,
        preferences: Preferences,
        additionalScriptPaths: [String],
        forceRescan: Bool = false,
        scanStore: RepositoryIdentityScanStore,
        onClose: @escaping () -> Void
    ) {
        self.repository = repository
        self.preferences = preferences
        self.additionalScriptPaths = additionalScriptPaths
        self.forceRescan = forceRescan
        self.scanStore = scanStore
        self.onClose = onClose
        self._result = State(
            initialValue: forceRescan ? .empty(repositoryID: repository.id) : scanStore.result(for: repository.id) ?? .empty(repositoryID: repository.id)
        )
    }

    private var isRunning: Bool {
        result.categories.values.contains { $0.phase == .running || $0.phase == .waiting }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Repository Scan")
                        .font(.title3.weight(.semibold))
                    Text(repository.name)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
            }

            VStack(spacing: 10) {
                ForEach(RepositoryIdentityScanCategory.allCases) { category in
                    RepositoryIdentityCategoryRow(
                        category: category,
                        result: result[category]
                    )
                }
            }

            HStack {
                if result.isFinished {
                    Label("Scan complete", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Label("Scanning repository contents", systemImage: "clock")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(isRunning ? "Cancel" : "Close") {
                    if isRunning {
                        task?.cancel()
                        markCancelled()
                    } else {
                        onClose()
                    }
                }
                .keyboardShortcut(.cancelAction)
                Button("Done") { onClose() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(isRunning)
            }
            .font(.callout)
        }
        .padding(22)
        .frame(width: 520)
        .onAppear { startIfNeeded() }
        .onDisappear { task?.cancel() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Repository self-identification scan")
    }

    private func startIfNeeded() {
        guard task == nil, !result.isFinished else { return }
        task = Task {
            let final = await RepositoryIdentityScanner.scan(
                repository: repository,
                preferences: preferences,
                additionalScriptPaths: additionalScriptPaths
            ) { progress in
                result = progress
                scanStore.update(progress)
            }
            guard !Task.isCancelled else { return }
            result = final
            scanStore.update(final)
        }
    }

    private func markCancelled() {
        task?.cancel()
        for category in RepositoryIdentityScanCategory.allCases {
            guard !result[category].isTerminal else { continue }
            var categoryResult = result[category]
            categoryResult.phase = .cancelled
            result.categories[category] = categoryResult
        }
        scanStore.update(result)
    }
}

private struct RepositoryIdentityCategoryRow: View {
    let category: RepositoryIdentityScanCategory
    let result: RepositoryIdentityCategoryResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: category.systemImage)
                    .frame(width: 18)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                Text(category.title)
                    .font(.headline)
                Spacer()
                Text(summary)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progressValue)
                .accessibilityLabel("\(category.title) progress")
                .accessibilityValue(accessibilityValue)

            Text(statusText)
                .font(.caption)
                .foregroundStyle(statusColor)
        }
        .padding(12)
        .background(Color.sectionSurface, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.sectionBorder, lineWidth: 1)
        )
    }

    private var progressValue: Double? {
        switch result.phase {
        case .waiting:
            return 0
        case .running:
            return nil
        case .complete:
            return 1
        case .cancelled, .failed:
            return 0
        }
    }

    private var summary: String {
        switch result.phase {
        case .waiting:
            return "Waiting"
        case .running:
            return "Scanning"
        case .complete:
            return "\(result.count)"
        case .cancelled:
            return "Cancelled"
        case .failed:
            return "Failed"
        }
    }

    private var statusText: String {
        switch result.phase {
        case .waiting:
            return "Waiting to start."
        case .running:
            return "Scanning this category."
        case .complete:
            return "\(result.count) found, \(result.skippedCount) skipped, \(result.unreadableCount) unreadable in \(elapsedText)."
        case .cancelled:
            return "Cancelled before this category finished."
        case .failed(let message):
            return message
        }
    }

    private var statusColor: Color {
        switch result.phase {
        case .failed:
            return .red
        case .cancelled:
            return .orange
        default:
            return .secondary
        }
    }

    private var elapsedText: String {
        result.elapsedSeconds < 1
            ? "\(Int((result.elapsedSeconds * 1000).rounded())) ms"
            : String(format: "%.1f s", result.elapsedSeconds)
    }

    private var accessibilityValue: String {
        switch result.phase {
        case .waiting:
            return "Waiting"
        case .running:
            return "In progress"
        case .complete:
            return "Complete, \(result.count) found, \(result.skippedCount) skipped, \(result.unreadableCount) unreadable"
        case .cancelled:
            return "Cancelled"
        case .failed:
            return "Failed"
        }
    }
}
