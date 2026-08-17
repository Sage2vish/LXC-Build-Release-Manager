import Foundation
import SwiftUI

/// One rendered log line: the raw text with ANSI escapes stripped, plus the pieces the log
/// view needs to draw it.
///
/// Extracted from `ContentView` so live output and saved-log files share one conversion path
/// and the parsing rules can be tested without a view.
struct DisplayLine: Identifiable, Hashable {
    let id: UUID
    let timestampText: String
    let text: String
    let stream: LogStream
    let ansiColor: TerminalLineColor?

    init(id: UUID = UUID(), timestampText: String, text: String, stream: LogStream, ansiColor: TerminalLineColor?) {
        self.id = id
        self.timestampText = timestampText
        self.text = text
        self.stream = stream
        self.ansiColor = ansiColor
    }
}

/// The subset of ANSI colours the build output actually uses.
enum TerminalLineColor: Hashable {
    case red
    case green
    case yellow
    case blue
    case magenta
    case cyan

    var color: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .yellow: return .yellow
        case .blue: return .blue
        case .magenta: return .pink
        case .cyan: return .cyan
        }
    }
}

enum LogFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case errors = "Errors"
    case warnings = "Warnings"
    case info = "Info"

    var id: String { rawValue }

    private static let errorWords = ["error", "Error", "ERROR", "failed", "Failed"]
    private static let warningWords = ["warning", "Warning", "WARNING"]

    func matches(_ text: String) -> Bool {
        switch self {
        case .all:
            return true
        case .errors:
            return Self.errorWords.contains { text.contains($0) }
        case .warnings:
            return Self.warningWords.contains { text.contains($0) }
        case .info:
            return !Self.errorWords.contains { text.contains($0) }
                && !Self.warningWords.contains { text.contains($0) }
        }
    }
}

/// Pure conversion from raw build output — live or read back from a `.log` file — into
/// renderable lines. No view state, no I/O.
enum LogPresentation {
    /// Live output already carries its stream and timestamp as structured data.
    static func displayLines(from logLines: [LogLine]) -> [DisplayLine] {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return logLines.map { line in
            let presentation = terminalPresentation(for: line.text)
            return DisplayLine(
                id: line.id,
                timestampText: formatter.string(from: line.timestamp),
                text: presentation.text,
                stream: line.stream,
                ansiColor: presentation.ansiColor
            )
        }
    }

    /// Saved logs are plain text: `[HH:mm:ss] [stderr] message`. Comment and blank lines are
    /// dropped so the header written by `LogFileService` does not appear as output.
    static func displayLines(fromFileContent content: String) -> [DisplayLine] {
        content
            .split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.hasPrefix("#") && !$0.isEmpty }
            .map { line -> DisplayLine in
                if line.hasPrefix("["), let closeBracket = line.firstIndex(of: "]") {
                    let timestamp = String(line[line.index(after: line.startIndex)..<closeBracket])
                    let rest = line[line.index(after: closeBracket)...].trimmingCharacters(in: .whitespaces)
                    let payload = streamPayload(from: String(rest))
                    let presentation = terminalPresentation(for: payload.text)
                    return DisplayLine(
                        timestampText: timestamp,
                        text: presentation.text,
                        stream: payload.stream,
                        ansiColor: presentation.ansiColor
                    )
                }
                let payload = streamPayload(from: String(line))
                let presentation = terminalPresentation(for: payload.text)
                return DisplayLine(
                    timestampText: "",
                    text: presentation.text,
                    stream: payload.stream,
                    ansiColor: presentation.ansiColor
                )
            }
    }

    /// Picks the line colour from any ANSI SGR sequence, then strips every escape so the text
    /// renders cleanly.
    static func terminalPresentation(for rawText: String) -> (text: String, ansiColor: TerminalLineColor?) {
        let color: TerminalLineColor?
        if rawText.contains("\u{001B}[31") || rawText.contains("\u{001B}[91") {
            color = .red
        } else if rawText.contains("\u{001B}[32") || rawText.contains("\u{001B}[92") {
            color = .green
        } else if rawText.contains("\u{001B}[33") || rawText.contains("\u{001B}[93") {
            color = .yellow
        } else if rawText.contains("\u{001B}[34") || rawText.contains("\u{001B}[94") {
            color = .blue
        } else if rawText.contains("\u{001B}[35") || rawText.contains("\u{001B}[95") {
            color = .magenta
        } else if rawText.contains("\u{001B}[36") || rawText.contains("\u{001B}[96") {
            color = .cyan
        } else {
            color = nil
        }
        let cleanText = rawText.replacingOccurrences(
            of: "\u{001B}\\[[0-9;]*m",
            with: "",
            options: .regularExpression
        )
        return (cleanText, color)
    }

    /// Recovers the stream from the marker `LogFileService` writes into saved logs.
    static func streamPayload(from text: String) -> (text: String, stream: LogStream) {
        if text.hasPrefix("[stderr] ") { return (String(text.dropFirst(9)), .stderr) }
        if text.hasPrefix("[system] ") { return (String(text.dropFirst(9)), .system) }
        return (text, .stdout)
    }

    /// Lines left after the filter and the search term are applied.
    static func visibleLines(
        _ lines: [DisplayLine],
        filter: LogFilter,
        searchText: String,
        caseSensitive: Bool
    ) -> [DisplayLine] {
        let filtered = lines.filter { filter.matches($0.text) }
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return filtered }
        return filtered.filter { line in
            caseSensitive
                ? line.text.contains(term)
                : line.text.range(of: term, options: .caseInsensitive) != nil
        }
    }

    /// Number of lines containing the search term, used for the "n matches" readout.
    static func matchCount(
        _ lines: [DisplayLine],
        searchText: String,
        caseSensitive: Bool
    ) -> Int {
        let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return 0 }
        return lines.filter { line in
            caseSensitive
                ? line.text.contains(term)
                : line.text.range(of: term, options: .caseInsensitive) != nil
        }.count
    }
}
