import Foundation

enum BuildStatus: String, Codable, Equatable {
    case running
    case success
    case failed
    case cancelled
}

struct LogLine: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let text: String
}

struct BuildRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let repositoryID: UUID
    let scriptFileName: String
    let scriptLabel: String
    let startedAt: Date
    var status: BuildStatus
    var durationSeconds: TimeInterval
    let logFileName: String

    init(
        id: UUID = UUID(),
        repositoryID: UUID,
        scriptFileName: String,
        scriptLabel: String,
        startedAt: Date,
        status: BuildStatus,
        durationSeconds: TimeInterval,
        logFileName: String
    ) {
        self.id = id
        self.repositoryID = repositoryID
        self.scriptFileName = scriptFileName
        self.scriptLabel = scriptLabel
        self.startedAt = startedAt
        self.status = status
        self.durationSeconds = durationSeconds
        self.logFileName = logFileName
    }
}

struct RepositoryStats {
    let totalBuilds: Int
    let successCount: Int
    let failureCount: Int
    let successRate: Double
    let averageDuration: TimeInterval
    let mostRecent: BuildRecord?
    let lastFailed: BuildRecord?
}
