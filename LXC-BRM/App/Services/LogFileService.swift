import Foundation
import AppKit

enum LogFileService {
    static func logsDirectoryURL(for repository: Repository, buildFolderName: String = "build", logsSubdirectory: String = "logs") -> URL? {
        guard case .local(let path) = repository.source else { return nil }
        return URL(fileURLWithPath: path)
            .appendingPathComponent(buildFolderName, isDirectory: true)
            .appendingPathComponent(logsSubdirectory, isDirectory: true)
    }

    static func timestampedFileName(prefix: String = "build", at date: Date, ext: String = "log") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return "\(prefix)-\(formatter.string(from: date)).\(ext)"
    }

    static func formattedContent(
        lines: [LogLine],
        script: BuildScript,
        status: BuildStatus,
        startedAt: Date,
        timestampFormat: String = "[HH:mm:ss]"
    ) -> String {
        let formatter = DateFormatter()
        let cleanedFormat = timestampFormat
            .replacingOccurrences(of: "[", with: "")
            .replacingOccurrences(of: "]", with: "")
        formatter.dateFormat = cleanedFormat.isEmpty ? "HH:mm:ss" : cleanedFormat
        let renderedLines = lines.map { "[\(formatter.string(from: $0.timestamp))] \($0.text)" }
        return "# \(script.fileName) — \(status.rawValue)\n\n" + renderedLines.joined(separator: "\n")
    }

    private static func stringEncoding(named name: String) -> String.Encoding {
        switch name {
        case "UTF-8", "System":
            return .utf8
        default:
            return .utf8
        }
    }

    @discardableResult
    static func write(
        lines: [LogLine],
        repository: Repository,
        script: BuildScript,
        status: BuildStatus,
        startedAt: Date,
        buildFolderName: String = "build",
        logsSubdirectory: String = "logs",
        timestampFormat: String = "[HH:mm:ss]",
        encodingName: String = "UTF-8",
        maxLogFileSizeMB: Int = 100,
        retentionDays: Int = 30,
        maxStoredLogs: Int = 100
    ) -> String {
        let fileName = timestampedFileName(at: startedAt)
        let contents = formattedContent(
            lines: lines,
            script: script,
            status: status,
            startedAt: startedAt,
            timestampFormat: timestampFormat
        )
        let finalContents = contents.truncated(toMaxByteCount: maxLogFileSizeMB > 0 ? maxLogFileSizeMB * 1024 * 1024 : 0)

        guard let directory = logsDirectoryURL(for: repository, buildFolderName: buildFolderName, logsSubdirectory: logsSubdirectory) else { return fileName }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(fileName)
        try? finalContents.write(to: fileURL, atomically: true, encoding: stringEncoding(named: encodingName))
        prune(directory: directory, retentionDays: retentionDays, maxStoredLogs: maxStoredLogs)
        return fileName
    }

    static func read(
        fileName: String,
        repository: Repository,
        buildFolderName: String = "build",
        logsSubdirectory: String = "logs",
        encodingName: String = "UTF-8"
    ) -> String? {
        guard let directory = logsDirectoryURL(for: repository, buildFolderName: buildFolderName, logsSubdirectory: logsSubdirectory) else { return nil }
        return try? String(contentsOf: directory.appendingPathComponent(fileName), encoding: stringEncoding(named: encodingName))
    }

    @MainActor
    static func export(content: String, suggestedName: String) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = []
        panel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func prune(directory: URL, retentionDays: Int, maxStoredLogs: Int) {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else { return }

        let logFiles = files
            .filter { $0.lastPathComponent.hasPrefix("build-") && $0.pathExtension == "log" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }

        if retentionDays > 0 {
            let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? .distantPast
            for file in logFiles {
                if let values = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
                   let modified = values.contentModificationDate,
                   modified < cutoff {
                    try? fileManager.removeItem(at: file)
                }
            }
        }

        if maxStoredLogs > 0 {
            let remaining = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
            let sorted = remaining
                .filter { $0.lastPathComponent.hasPrefix("build-") && $0.pathExtension == "log" }
                .sorted { $0.lastPathComponent > $1.lastPathComponent }
            for file in sorted.dropFirst(maxStoredLogs) {
                try? fileManager.removeItem(at: file)
            }
        }
    }
}

private extension String {
    func truncated(toMaxByteCount limit: Int) -> String {
        guard limit > 0, utf8.count > limit else { return self }

        let separator = "\n"
        let parts = components(separatedBy: separator)
        guard parts.count > 1 else {
            return String(decoding: utf8.prefix(limit), as: UTF8.self)
        }

        var kept: [String] = []
        var currentByteCount = 0
        for part in parts.reversed() {
            let partCount = part.utf8.count
            let separatorCount = kept.isEmpty ? 0 : separator.utf8.count
            if currentByteCount + partCount + separatorCount > limit { break }
            kept.insert(part, at: 0)
            currentByteCount += partCount + separatorCount
        }

        guard !kept.isEmpty else {
            return String(decoding: utf8.prefix(limit), as: UTF8.self)
        }

        let note = "# Log truncated to fit the configured maximum size.\n"
        let combined = kept.joined(separator: separator)
        if (note + combined).utf8.count <= limit {
            return note + combined
        }
        return combined
    }
}
