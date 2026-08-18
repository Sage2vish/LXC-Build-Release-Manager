import Foundation

enum BuildStatus: String, Codable, Equatable {
    case running
    case success
    case failed
    case cancelled
}

enum BuildExecutionPhase: Equatable {
    case idle
    case starting
    case running
    case stopping
    case succeeded
    case failed
    case cancelled

    var isActive: Bool {
        switch self {
        case .starting, .running, .stopping: return true
        case .idle, .succeeded, .failed, .cancelled: return false
        }
    }
}

enum LogStream: String, Codable, Hashable {
    case stdout
    case stderr
    case system
}

struct LogLine: Identifiable, Hashable {
    let id = UUID()
    let timestamp: Date
    let text: String
    let stream: LogStream

    init(timestamp: Date, text: String, stream: LogStream = .stdout) {
        self.timestamp = timestamp
        self.text = text
        self.stream = stream
    }
}

struct BuildRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let logSessionID: UUID
    let repositoryID: UUID
    let scriptFileName: String
    let scriptLabel: String
    let startedAt: Date
    var status: BuildStatus
    var durationSeconds: TimeInterval
    let logFileName: String
    let processID: Int32?
    let exitCode: Int32?
    let terminationReason: String?
    let parameterValues: BuildParameterValues

    init(
        id: UUID = UUID(),
        logSessionID: UUID = UUID(),
        repositoryID: UUID,
        scriptFileName: String,
        scriptLabel: String,
        startedAt: Date,
        status: BuildStatus,
        durationSeconds: TimeInterval,
        logFileName: String,
        processID: Int32? = nil,
        exitCode: Int32? = nil,
        terminationReason: String? = nil,
        parameterValues: BuildParameterValues = [:]
    ) {
        self.id = id
        self.logSessionID = logSessionID
        self.repositoryID = repositoryID
        self.scriptFileName = scriptFileName
        self.scriptLabel = scriptLabel
        self.startedAt = startedAt
        self.status = status
        self.durationSeconds = durationSeconds
        self.logFileName = logFileName
        self.processID = processID
        self.exitCode = exitCode
        self.terminationReason = terminationReason
        self.parameterValues = parameterValues
    }

    private enum CodingKeys: String, CodingKey {
        case id, logSessionID, repositoryID, scriptFileName, scriptLabel, startedAt, status, durationSeconds, logFileName, processID, exitCode, terminationReason, parameterValues
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        logSessionID = try container.decodeIfPresent(UUID.self, forKey: .logSessionID) ?? id
        repositoryID = try container.decode(UUID.self, forKey: .repositoryID)
        scriptFileName = try container.decode(String.self, forKey: .scriptFileName)
        scriptLabel = try container.decode(String.self, forKey: .scriptLabel)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        status = try container.decode(BuildStatus.self, forKey: .status)
        durationSeconds = try container.decode(TimeInterval.self, forKey: .durationSeconds)
        logFileName = try container.decode(String.self, forKey: .logFileName)
        processID = try container.decodeIfPresent(Int32.self, forKey: .processID)
        exitCode = try container.decodeIfPresent(Int32.self, forKey: .exitCode)
        terminationReason = try container.decodeIfPresent(String.self, forKey: .terminationReason)
        parameterValues = try container.decodeIfPresent(BuildParameterValues.self, forKey: .parameterValues) ?? [:]
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

    /// Statistics for exactly these records.
    ///
    /// Pure, so the same arithmetic serves the store's all-time figures and any date-ranged view
    /// without two implementations that can disagree about what a success rate means. Expects
    /// records newest-first, which is how the store hands them out.
    static func make(from records: [BuildRecord]) -> RepositoryStats {
        let total = records.count
        let successCount = records.filter { $0.status == .success }.count
        let failureCount = records.filter { $0.status == .failed }.count
        return RepositoryStats(
            totalBuilds: total,
            successCount: successCount,
            failureCount: failureCount,
            // A repository with no runs has no success rate. Zero is the honest answer only
            // because the view shows a dash whenever there are no builds at all.
            successRate: total > 0 ? Double(successCount) / Double(total) : 0,
            averageDuration: total > 0 ? records.map(\.durationSeconds).reduce(0, +) / Double(total) : 0,
            mostRecent: records.first,
            lastFailed: records.first { $0.status == .failed }
        )
    }
}

/// How far back the Overview tab counts.
///
/// "All time" stays the default: it is what the history actually contains, and a range that
/// silently excluded runs would make a success rate mean something different from one glance to
/// the next.
enum StatsRange: String, CaseIterable, Identifiable {
    case allTime = "All time"
    case week = "Last 7 days"
    case month = "Last 30 days"
    case quarter = "Last 90 days"

    var id: String { rawValue }

    /// Days included, or `nil` for everything.
    var days: Int? {
        switch self {
        case .allTime: return nil
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        }
    }

    /// The records this range covers, counted back from `now`.
    func filter(_ records: [BuildRecord], now: Date = Date()) -> [BuildRecord] {
        guard let days else { return records }
        let cutoff = now.addingTimeInterval(-Double(days) * 24 * 60 * 60)
        return records.filter { $0.startedAt >= cutoff }
    }
}
