import Foundation

@MainActor
final class BuildHistoryStore: ObservableObject {
    @Published private(set) var recordsByRepository: [UUID: [BuildRecord]] = [:]

    private let storeURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("LXC-BRM", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        storeURL = folder.appendingPathComponent("build-history.json")
        load()
    }

    func records(for repositoryID: UUID) -> [BuildRecord] {
        (recordsByRepository[repositoryID] ?? []).sorted { $0.startedAt > $1.startedAt }
    }

    func record(_ record: BuildRecord) {
        recordsByRepository[record.repositoryID, default: []].append(record)
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
        guard let data = try? Data(contentsOf: storeURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([UUID: [BuildRecord]].self, from: data) else { return }
        recordsByRepository = decoded
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(recordsByRepository) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }
}
