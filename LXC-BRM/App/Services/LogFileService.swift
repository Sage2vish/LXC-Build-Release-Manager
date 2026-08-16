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
        var contents = "# \(script.fileName) — \(status.rawValue)\n\n"
        contents += lines
            .map { "[\(formatter.string(from: $0.timestamp))] \($0.text)" }
            .joined(separator: "\n")
        return contents
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

        guard let directory = logsDirectoryURL(for: repository, buildFolderName: buildFolderName, logsSubdirectory: logsSubdirectory) else { return fileName }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(fileName)
        try? contents.write(to: fileURL, atomically: true, encoding: stringEncoding(named: encodingName))
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
