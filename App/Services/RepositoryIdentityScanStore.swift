import Foundation

enum RepositoryIdentityScanCategory: String, CaseIterable, Identifiable {
    case scripts
    case logs
    case markdown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .scripts: return "Build scripts"
        case .logs: return "Saved logs"
        case .markdown: return "Markdown documents"
        }
    }

    var systemImage: String {
        switch self {
        case .scripts: return "terminal"
        case .logs: return "doc.text.magnifyingglass"
        case .markdown: return "doc.richtext"
        }
    }
}

enum RepositoryIdentityScanPhase: Equatable {
    case waiting
    case running
    case complete
    case cancelled
    case failed(String)
}

struct RepositoryIdentityCategoryResult: Equatable {
    var phase: RepositoryIdentityScanPhase = .waiting
    var count = 0
    var skippedCount = 0
    var unreadableCount = 0
    var elapsedSeconds: TimeInterval = 0

    var isTerminal: Bool {
        switch phase {
        case .complete, .cancelled, .failed:
            return true
        case .waiting, .running:
            return false
        }
    }
}

struct RepositoryIdentityScanResult: Equatable {
    let repositoryID: Repository.ID
    var categories: [RepositoryIdentityScanCategory: RepositoryIdentityCategoryResult]
    var buildScanResult: BuildScanResult?

    static func empty(repositoryID: Repository.ID) -> RepositoryIdentityScanResult {
        RepositoryIdentityScanResult(
            repositoryID: repositoryID,
            categories: Dictionary(
                uniqueKeysWithValues: RepositoryIdentityScanCategory.allCases.map {
                    ($0, RepositoryIdentityCategoryResult())
                }
            ),
            buildScanResult: nil
        )
    }

    subscript(category: RepositoryIdentityScanCategory) -> RepositoryIdentityCategoryResult {
        categories[category] ?? RepositoryIdentityCategoryResult()
    }

    var isFinished: Bool {
        categories.values.allSatisfy(\.isTerminal)
    }
}

@MainActor
final class RepositoryIdentityScanStore: ObservableObject {
    static let shared = RepositoryIdentityScanStore()

    @Published private(set) var results: [Repository.ID: RepositoryIdentityScanResult] = [:]

    func result(for repositoryID: Repository.ID) -> RepositoryIdentityScanResult? {
        results[repositoryID]
    }

    func hasCompletedResult(for repositoryID: Repository.ID) -> Bool {
        results[repositoryID]?.isFinished == true
    }

    func update(_ result: RepositoryIdentityScanResult) {
        results[result.repositoryID] = result
    }

    func remove(_ repositoryID: Repository.ID) {
        results[repositoryID] = nil
    }
}

enum RepositoryIdentityScanner {
    static func scan(
        repository: Repository,
        preferences: Preferences,
        additionalScriptPaths: [String],
        progress: @MainActor @escaping (RepositoryIdentityScanResult) -> Void
    ) async -> RepositoryIdentityScanResult {
        var result = RepositoryIdentityScanResult.empty(repositoryID: repository.id)

        await mark(.scripts, phase: .running, in: &result, progress: progress)
        await mark(.logs, phase: .running, in: &result, progress: progress)
        await mark(.markdown, phase: .running, in: &result, progress: progress)

        guard case .local(let rootPath) = repository.source else {
            for category in RepositoryIdentityScanCategory.allCases {
                await update(category, in: &result, progress: progress) {
                    $0.phase = .failed("Only local repositories can be self-identified.")
                }
            }
            return result
        }

        async let scripts = scanScripts(
            rootPath: rootPath,
            preferences: preferences,
            additionalScriptPaths: additionalScriptPaths
        )
        async let logs = scanLogs(rootPath: rootPath, preferences: preferences)
        async let markdown = scanMarkdown(rootPath: rootPath)

        let scriptOutcome = await scripts
        await update(.scripts, in: &result, progress: progress) {
            $0.phase = .complete
            $0.count = scriptOutcome.count
            $0.skippedCount = scriptOutcome.skipped
            $0.unreadableCount = scriptOutcome.unreadable
            $0.elapsedSeconds = scriptOutcome.elapsed
        }
        result.buildScanResult = scriptOutcome.buildScanResult
        await progress(result)

        let logOutcome = await logs
        await update(.logs, in: &result, progress: progress) {
            $0.phase = .complete
            $0.count = logOutcome.count
            $0.skippedCount = logOutcome.skipped
            $0.unreadableCount = logOutcome.unreadable
            $0.elapsedSeconds = logOutcome.elapsed
        }

        let markdownOutcome = await markdown
        await update(.markdown, in: &result, progress: progress) {
            $0.phase = .complete
            $0.count = markdownOutcome.count
            $0.skippedCount = markdownOutcome.skipped
            $0.unreadableCount = markdownOutcome.unreadable
            $0.elapsedSeconds = markdownOutcome.elapsed
        }

        return result
    }

    private static func mark(
        _ category: RepositoryIdentityScanCategory,
        phase: RepositoryIdentityScanPhase,
        in result: inout RepositoryIdentityScanResult,
        progress: @MainActor @escaping (RepositoryIdentityScanResult) -> Void
    ) async {
        await update(category, in: &result, progress: progress) { $0.phase = phase }
    }

    private static func update(
        _ category: RepositoryIdentityScanCategory,
        in result: inout RepositoryIdentityScanResult,
        progress: @MainActor @escaping (RepositoryIdentityScanResult) -> Void,
        mutation: (inout RepositoryIdentityCategoryResult) -> Void
    ) async {
        var categoryResult = result[category]
        mutation(&categoryResult)
        result.categories[category] = categoryResult
        await progress(result)
    }

    private struct CategoryOutcome {
        var count: Int
        var skipped: Int
        var unreadable: Int
        var elapsed: TimeInterval
        var buildScanResult: BuildScanResult?
    }

    private static func scanScripts(
        rootPath: String,
        preferences: Preferences,
        additionalScriptPaths: [String]
    ) async -> CategoryOutcome {
        let started = Date()
        let buildResult = BuildScriptScanner.scanLocal(
            path: rootPath,
            options: BuildScanOptions(preferences: preferences),
            additionalScriptPaths: additionalScriptPaths
        )
        let count: Int
        let skipped: Int
        switch buildResult {
        case .success(let scripts):
            count = scripts.count
            skipped = max(0, additionalScriptPaths.count - scripts.filter { additionalScriptPaths.contains($0.path) }.count)
        case .missingBuildFolder, .emptyScripts, .unreachable:
            count = 0
            skipped = 0
        }
        return CategoryOutcome(
            count: count,
            skipped: skipped,
            unreadable: 0,
            elapsed: Date().timeIntervalSince(started),
            buildScanResult: buildResult
        )
    }

    private static func scanLogs(rootPath: String, preferences: Preferences) async -> CategoryOutcome {
        let started = Date()
        let directory = URL(fileURLWithPath: rootPath, isDirectory: true)
            .appendingPathComponent(preferences.defaultBuildFolderName, isDirectory: true)
            .appendingPathComponent("logs", isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory) else {
            return CategoryOutcome(count: 0, skipped: 0, unreadable: 0, elapsed: Date().timeIntervalSince(started))
        }
        guard isDirectory.boolValue else {
            return CategoryOutcome(count: 0, skipped: 1, unreadable: 0, elapsed: Date().timeIntervalSince(started))
        }
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return CategoryOutcome(count: 0, skipped: 0, unreadable: 1, elapsed: Date().timeIntervalSince(started))
        }
        var count = 0
        var skipped = 0
        for entry in entries {
            let isRegular = (try? entry.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile ?? false
            if isRegular, entry.pathExtension.lowercased() == "log" {
                count += 1
            } else {
                skipped += 1
            }
        }
        return CategoryOutcome(count: count, skipped: skipped, unreadable: 0, elapsed: Date().timeIntervalSince(started))
    }

    private static func scanMarkdown(rootPath: String) async -> CategoryOutcome {
        let started = Date()
        let stats = markdownStats(rootPath: rootPath)
        return CategoryOutcome(
            count: stats.count,
            skipped: stats.skipped,
            unreadable: stats.unreadable,
            elapsed: Date().timeIntervalSince(started)
        )
    }

    private static func markdownStats(rootPath: String) -> (count: Int, skipped: Int, unreadable: Int) {
        let root = URL(fileURLWithPath: rootPath, isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return (0, 0, 1)
        }
        return markdownStats(in: root)
    }

    private static func markdownStats(in directory: URL) -> (count: Int, skipped: Int, unreadable: Int) {
        if Task.isCancelled { return (0, 0, 0) }
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return (0, 0, 1)
        }

        var count = 0
        var skipped = 0
        var unreadable = 0
        for entry in entries {
            let values = try? entry.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])
            if values?.isDirectory == true {
                if MarkdownFileTree.shouldSkip(directoryName: entry.lastPathComponent) {
                    skipped += 1
                    continue
                }
                let nested = markdownStats(in: entry)
                count += nested.count
                skipped += nested.skipped
                unreadable += nested.unreadable
            } else if values?.isRegularFile == true, MarkdownFileTree.isMarkdown(entry) {
                count += 1
            }
        }
        return (count, skipped, unreadable)
    }
}
