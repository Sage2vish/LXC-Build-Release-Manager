import Foundation

@MainActor
final class BuildHistoryStore: ObservableObject {
    static let shared = BuildHistoryStore()

    @Published private(set) var recordsByRepository: [UUID: [BuildRecord]] = [:]
    /// Set when a load or save fails, so history loss is visible rather than silent.
    @Published private(set) var lastError: AppDataError?

    private let storeURL: URL

    init(storeURL: URL? = nil) {
        if let storeURL {
            self.storeURL = storeURL
            try? FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        } else {
            self.storeURL = AppDataLocations.url(for: .buildHistory)
        }
        load()
    }

    func records(for repositoryID: UUID) -> [BuildRecord] {
        (recordsByRepository[repositoryID] ?? []).sorted { $0.startedAt > $1.startedAt }
    }

    func record(_ record: BuildRecord) {
        recordsByRepository[record.repositoryID, default: []].append(record)
        save()
    }

    func clearAll() {
        recordsByRepository = [:]
        save()
    }

    func lastRun(for repositoryID: UUID, scriptFileName: String) -> BuildRecord? {
        records(for: repositoryID).first { $0.scriptFileName == scriptFileName }
    }

    func stats(for repositoryID: UUID) -> RepositoryStats {
        let all = records(for: repositoryID)
        let successCount = all.filter { $0.status == .success }.count
        let failureCount = all.filter { $0.status == .failed }.count
        let total = all.count
        let successRate = total > 0 ? Double(successCount) / Double(total) : 0
        let averageDuration = total > 0 ? all.map(\.durationSeconds).reduce(0, +) / Double(total) : 0
        return RepositoryStats(
            totalBuilds: total,
            successCount: successCount,
            failureCount: failureCount,
            successRate: successRate,
            averageDuration: averageDuration,
            mostRecent: all.first,
            lastFailed: all.first { $0.status == .failed }
        )
    }

    private func load() {
        switch JSONFileStore(url: storeURL).load([UUID: [BuildRecord]].self) {
        case .success(let decoded):
            guard let decoded else { return }
            recordsByRepository = decoded
        case .failure(let error):
            lastError = error
        }
    }

    /// Encoded on the main actor, written off it: history can grow large and a build finishing
    /// should never block the UI on disk I/O.
    private func save() {
        let destination = storeURL
        do {
            let data = try JSONFileStore.makeEncoder().encode(recordsByRepository)
            DispatchQueue.global(qos: .utility).async {
                try? data.write(to: destination, options: .atomic)
            }
        } catch {
            lastError = .unwritable(file: destination.lastPathComponent, reason: error.localizedDescription)
        }
    }
}
