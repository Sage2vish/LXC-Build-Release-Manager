import Foundation

/// The single source of truth for where LXC-BRM keeps its data.
///
/// Every store previously rebuilt this path itself, five times over. The file names are part of
/// the product contract — existing installs must keep loading — so they are named here once and
/// must not change without a migration.
///
/// Build logs deliberately do **not** live here: they belong to the repository's own
/// `build/logs/` folder, which is part of what the user ships.
enum AppDataLocations {
    static let folderName = "LXC-BRM"

    enum File: String, CaseIterable {
        case repositories = "projects.json"
        case selectedRepository = "selected-repository.json"
        case buildHistory = "build-history.json"
        case preferences = "preferences.json"
        case buildWorkspaceState = "build-workspace-state.json"
    }

    /// Application Support directory for the app, created on demand.
    static func supportDirectory(fileManager: FileManager = .default) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent(folderName, isDirectory: true)
        try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    static func url(for file: File, fileManager: FileManager = .default) -> URL {
        supportDirectory(fileManager: fileManager).appendingPathComponent(file.rawValue)
    }
}

/// Why a read or write failed, so callers can surface something better than a silent `try?`.
enum AppDataError: LocalizedError, Equatable {
    case unreadable(file: String, reason: String)
    case corrupt(file: String, reason: String)
    case unwritable(file: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .unreadable(let file, let reason):
            return "Could not read \(file): \(reason)"
        case .corrupt(let file, let reason):
            return "\(file) is not valid JSON and was ignored: \(reason)"
        case .unwritable(let file, let reason):
            return "Could not save \(file): \(reason)"
        }
    }
}

/// Small JSON boundary shared by every store: one encoder configuration, atomic writes, and
/// typed failures instead of a discarded `try?`.
struct JSONFileStore {
    let url: URL
    private let fileManager: FileManager

    init(url: URL, fileManager: FileManager = .default) {
        self.url = url
        self.fileManager = fileManager
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    var exists: Bool { fileManager.fileExists(atPath: url.path) }

    /// Returns `nil` when the file simply does not exist yet — a first launch, not an error.
    func load<T: Decodable>(_ type: T.Type) -> Result<T?, AppDataError> {
        guard exists else { return .success(nil) }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            return .failure(.unreadable(file: url.lastPathComponent, reason: error.localizedDescription))
        }
        do {
            return .success(try Self.makeDecoder().decode(type, from: data))
        } catch {
            return .failure(.corrupt(file: url.lastPathComponent, reason: error.localizedDescription))
        }
    }

    func save<T: Encodable>(_ value: T) -> Result<Void, AppDataError> {
        do {
            let data = try Self.makeEncoder().encode(value)
            try data.write(to: url, options: .atomic)
            return .success(())
        } catch {
            return .failure(.unwritable(file: url.lastPathComponent, reason: error.localizedDescription))
        }
    }
}
