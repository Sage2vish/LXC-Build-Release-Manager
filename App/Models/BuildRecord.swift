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
}
