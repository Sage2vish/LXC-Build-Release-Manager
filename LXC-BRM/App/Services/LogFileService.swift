import Foundation
import AppKit

enum LogFileService {
    static func logsDirectoryURL(for repository: Repository) -> URL? {
        guard case .local(let path) = repository.source else { return nil }
        return URL(fileURLWithPath: path).appendingPathComponent("build/logs", isDirectory: true)
    }

    static func timestampedFileName(prefix: String = "build", at date: Date, ext: String = "log") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        return "\(prefix)-\(formatter.string(from: date)).\(ext)"
    }

    static func formattedContent(lines: [LogLine], script: BuildScript, status: BuildStatus, startedAt: Date) -> String {
        let lineFormatter = DateFormatter()
        lineFormatter.dateFormat = "HH:mm:ss"
        var contents = "# \(script.fileName) — \(status.rawValue)\n\n"
        contents += lines
            .map { "[\(lineFormatter.string(from: $0.timestamp))] \($0.text)" }
            .joined(separator: "\n")
        return contents
    }

    @discardableResult
    static func write(lines: [LogLine], repository: Repository, script: BuildScript, status: BuildStatus, startedAt: Date) -> String {
        let fileName = timestampedFileName(at: startedAt)
        let contents = formattedContent(lines: lines, script: script, status: status, startedAt: startedAt)

        guard let directory = logsDirectoryURL(for: repository) else { return fileName }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent(fileName)
        try? contents.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileName
    }

    static func read(fileName: String, repository: Repository) -> String? {
        guard let directory = logsDirectoryURL(for: repository) else { return nil }
        return try? String(contentsOf: directory.appendingPathComponent(fileName), encoding: .utf8)
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
}
