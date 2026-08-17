import Foundation

/// Internal diagnostics logging, gated by the Advanced preferences.
///
/// `verboseDebugLogging`, `logInternalDiagnosticsToFile`, and `diagnosticsLogLocation` were all
/// stored and shown in Preferences with nothing behind them. This gives them somewhere to land.
///
/// Deliberately best-effort: diagnostics must never take down a build or block the UI, so a
/// failure to write is swallowed here rather than surfaced. That is the one place in the app
/// where discarding an error is the right call.
enum DiagnosticsLog {
    enum Level: String {
        case info = "INFO"
        case debug = "DEBUG"
        case error = "ERROR"
    }

    /// Records a diagnostic line if the preferences ask for it.
    ///
    /// `.debug` lines are only written when verbose logging is on; `.info` and `.error` are
    /// written whenever file logging is enabled.
    static func write(
        _ level: Level,
        _ message: String,
        preferences: Preferences,
        date: Date = Date(),
        fileManager: FileManager = .default
    ) {
        guard shouldWrite(level, preferences: preferences) else { return }
        guard let url = logFileURL(preferences: preferences, fileManager: fileManager) else { return }

        let formatter = ISO8601DateFormatter()
        let line = "[\(formatter.string(from: date))] [\(level.rawValue)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if let handle = try? FileHandle(forWritingTo: url) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: url, options: .atomic)
        }
    }

    static func shouldWrite(_ level: Level, preferences: Preferences) -> Bool {
        guard preferences.logInternalDiagnosticsToFile else { return false }
        if level == .debug { return preferences.verboseDebugLogging }
        return true
    }

    /// Resolves `diagnosticsLogLocation`, expanding `~`, and creates the directory on demand.
    /// Returns `nil` when the location is unusable, which simply disables diagnostics.
    static func logFileURL(preferences: Preferences, fileManager: FileManager = .default) -> URL? {
        let raw = preferences.diagnosticsLogLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        let expanded = (raw as NSString).expandingTildeInPath
        let directory = URL(fileURLWithPath: expanded, isDirectory: true)
        guard (try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)) != nil else {
            return nil
        }
        return directory.appendingPathComponent("lxc-brm-diagnostics.log")
    }
}

/// GitHub API rate-limit handling.
///
/// Backs the "GitHub rate limit alerts" preference, which was stored and shown with nothing
/// reading it. A bare "status 403" tells the user nothing; this turns it into an actionable
/// message and warns before the quota actually runs out.
enum GitHubRateLimit {
    /// Parses the stored threshold string ("Warn me at 20%") into a percentage.
    /// Returns 0 when warnings are disabled or the value is unrecognised.
    static func warnPercent(_ setting: String) -> Int {
        guard let match = setting.range(of: #"\d+"#, options: .regularExpression),
              let value = Int(setting[match]) else {
            return 0
        }
        return min(max(value, 0), 100)
    }

    /// A message when the response is rate limited, or when the remaining quota has fallen to
    /// the configured threshold. `nil` means there is nothing to report.
    static func message(for response: HTTPURLResponse, warnPercent: Int) -> String? {
        message(
            statusCode: response.statusCode,
            remaining: header(response, "X-RateLimit-Remaining"),
            limit: header(response, "X-RateLimit-Limit"),
            warnPercent: warnPercent
        )
    }

    static func message(statusCode: Int, remaining: Int?, limit: Int?, warnPercent: Int) -> String? {
        // Exhausted: GitHub answers 403 with zero remaining.
        if statusCode == 403, let remaining, remaining == 0 {
            return "GitHub API rate limit reached. Add a personal access token in Preferences, or wait for the limit to reset."
        }
        guard warnPercent > 0, let remaining, let limit, limit > 0 else { return nil }
        let percentLeft = Int((Double(remaining) / Double(limit)) * 100)
        guard percentLeft <= warnPercent else { return nil }
        return "GitHub API quota is low: \(remaining) of \(limit) requests remaining."
    }

    private static func header(_ response: HTTPURLResponse, _ name: String) -> Int? {
        guard let raw = response.value(forHTTPHeaderField: name) else { return nil }
        return Int(raw)
    }
}
