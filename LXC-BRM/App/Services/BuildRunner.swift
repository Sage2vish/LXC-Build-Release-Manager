import Foundation
import Darwin
import Combine

@MainActor
final class BuildRunner: ObservableObject {
    @Published private(set) var logLines: [LogLine] = []
    @Published private(set) var runningScript: BuildScript?
    @Published private(set) var startedAt: Date?
    @Published private(set) var finishedAt: Date?

    private var process: Process?
    private var stdoutHandle: FileHandle?
    private var stderrHandle: FileHandle?
    private var wasCancelled = false
    private var sleepActivityToken: NSObjectProtocol?
    private var timeoutWorkItem: DispatchWorkItem?

    var isRunning: Bool { runningScript != nil }

    var duration: TimeInterval {
        guard let startedAt else { return 0 }
        return (finishedAt ?? Date()).timeIntervalSince(startedAt)
    }

    func start(script: BuildScript, repository: Repository, historyStore: BuildHistoryStore, preferences: Preferences) {
        guard !isRunning, case .local(let repositoryPath) = repository.source else { return }

        logLines = []
        runningScript = script
        startedAt = Date()
        finishedAt = nil
        wasCancelled = false

        let process = Process()
        process.executableURL = URL(fileURLWithPath: preferences.defaultShell)
        process.arguments = [script.path]
        process.currentDirectoryURL = workingDirectoryURL(for: repositoryPath, preferences: preferences)

        if !preferences.environmentVariables.isEmpty {
            var environment = ProcessInfo.processInfo.environment
            for entry in preferences.environmentVariables where !entry.key.isEmpty {
                environment[entry.key] = entry.value
            }
            process.environment = environment
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.handleOutput(handle.availableData)
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.handleOutput(handle.availableData)
        }

        process.terminationHandler = { [weak self] proc in
            Task { @MainActor in
                self?.finish(exitCode: proc.terminationStatus, repository: repository, script: script, historyStore: historyStore, preferences: preferences)
            }
        }

        self.process = process
        stdoutHandle = stdoutPipe.fileHandleForReading
        stderrHandle = stderrPipe.fileHandleForReading

        if preferences.preventSleepDuringBuild {
            sleepActivityToken = ProcessInfo.processInfo.beginActivity(
                options: [.idleSystemSleepDisabled],
                reason: "LXC-BRM build running: \(script.label)"
            )
        }

        BuildNotificationService.shared.notify(
            .started,
            repository: repository,
            script: script,
            preferences: preferences
        )

        do {
            try process.run()
            scheduleTimeout(preferences: preferences)
        } catch {
            logLines.append(LogLine(timestamp: Date(), text: "Failed to start: \(error.localizedDescription)"))
            finish(exitCode: -1, repository: repository, script: script, historyStore: historyStore, preferences: preferences)
        }
    }

    func cancel(preferences: Preferences) {
        guard let process, isRunning else { return }
        wasCancelled = true
        if preferences.terminateChildProcessesOnStop {
            Self.killProcessTree(rootPID: process.processIdentifier)
        } else {
            process.terminate()
        }
    }

    private func scheduleTimeout(preferences: Preferences) {
        let perBuildMinutes = preferences.buildTimeoutMinutes
        let globalMinutes = preferences.globalBuildTimeoutMinutes
        let effectiveMinutes: Int
        if globalMinutes > 0 && perBuildMinutes > 0 {
            effectiveMinutes = min(perBuildMinutes, globalMinutes)
        } else {
            effectiveMinutes = max(perBuildMinutes, globalMinutes)
        }
        guard effectiveMinutes > 0 else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.isRunning else { return }
            self.cancel(preferences: preferences)
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(effectiveMinutes * 60), execute: workItem)
    }

    nonisolated private func handleOutput(_ data: Data) {
        guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard !lines.isEmpty else { return }
        Task { @MainActor [weak self] in
            self?.appendLines(lines)
        }
    }

    private func appendLines(_ lines: [String]) {
        let now = Date()
        logLines.append(contentsOf: lines.map { LogLine(timestamp: now, text: $0) })
    }

    private func finish(exitCode: Int32, repository: Repository, script: BuildScript, historyStore: BuildHistoryStore, preferences: Preferences) {
        guard runningScript != nil else { return }
        stdoutHandle?.readabilityHandler = nil
        stderrHandle?.readabilityHandler = nil
        finishedAt = Date()
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil

        if let token = sleepActivityToken {
            ProcessInfo.processInfo.endActivity(token)
            sleepActivityToken = nil
        }

        let finalStatus: BuildStatus = wasCancelled ? .cancelled : (exitCode == 0 ? .success : .failed)
        let notificationKind: BuildNotificationService.Kind = {
            switch finalStatus {
            case .success: return .succeeded
            case .failed: return .failed
            case .cancelled: return .cancelled
            case .running: return .started
            }
        }()

        if wasCancelled && !preferences.preservePartialOutputOnCancellation {
            logLines = []
        }

        var logFileName = ""
        let shouldSaveLogs = preferences.automaticallySaveLogs || preferences.saveLogsAutomatically
        if shouldSaveLogs {
            logFileName = LogFileService.write(
                lines: logLines,
                repository: repository,
                script: script,
                status: finalStatus,
                startedAt: startedAt ?? Date(),
                buildFolderName: preferences.defaultBuildFolderName,
                logsSubdirectory: preferences.logsSubdirectory,
                timestampFormat: preferences.timestampFormat,
                encodingName: preferences.logEncoding,
                maxLogFileSizeMB: preferences.maxLogFileSizeMB,
                retentionDays: preferences.logRetentionDays,
                maxStoredLogs: preferences.maxStoredLogs
            )
        }

        historyStore.record(
            BuildRecord(
                repositoryID: repository.id,
                scriptFileName: script.fileName,
                scriptLabel: script.label,
                startedAt: startedAt ?? Date(),
                status: finalStatus,
                durationSeconds: duration,
                logFileName: logFileName
            )
        )

        BuildNotificationService.shared.notify(
            notificationKind,
            repository: repository,
            script: script,
            preferences: preferences
        )

        runningScript = nil
        process = nil
        wasCancelled = false
    }

    private func workingDirectoryURL(for repositoryPath: String, preferences: Preferences) -> URL {
        let repositoryURL = URL(fileURLWithPath: repositoryPath)
        switch preferences.workingDirectoryChoice {
        case "Custom":
            let buildFolder = repositoryURL.appendingPathComponent(preferences.defaultBuildFolderName, isDirectory: true)
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: buildFolder.path, isDirectory: &isDirectory), isDirectory.boolValue {
                return buildFolder
            }
            return repositoryURL
        default:
            return repositoryURL
        }
    }

    /// Best-effort recursive kill: Foundation's Process API doesn't expose real process-group
    /// control, so this walks `pgrep -P` children before signalling the root process.
    nonisolated private static func killProcessTree(rootPID: Int32) {
        let pgrep = Process()
        pgrep.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        pgrep.arguments = ["-P", "\(rootPID)"]
        let pipe = Pipe()
        pgrep.standardOutput = pipe
        pgrep.standardError = Pipe()
        guard (try? pgrep.run()) != nil else {
            kill(rootPID, SIGTERM)
            return
        }
        pgrep.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            for line in output.split(separator: "\n") {
                if let childPID = Int32(line) {
                    killProcessTree(rootPID: childPID)
                }
            }
        }
        kill(rootPID, SIGTERM)
    }
}

@MainActor
final class BuildRunnerRegistry: ObservableObject {
    static let shared = BuildRunnerRegistry()

    private var runners: [UUID: BuildRunner] = [:]
    private var cancellables: [UUID: AnyCancellable] = [:]

    func runner(for repositoryID: UUID) -> BuildRunner {
        if let existing = runners[repositoryID] { return existing }
        let runner = BuildRunner()
        runners[repositoryID] = runner
        cancellables[repositoryID] = runner.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        return runner
    }

    var hasAnyRunningBuild: Bool {
        runners.values.contains { $0.isRunning }
    }

    var runningCount: Int {
        runners.values.filter(\.isRunning).count
    }
}
