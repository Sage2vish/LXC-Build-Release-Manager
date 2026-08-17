import Combine
import Darwin
import Foundation

@MainActor
final class BuildRunner: ObservableObject {
    @Published private(set) var logLines: [LogLine] = []
    @Published private(set) var runningScript: BuildScript?
    @Published private(set) var startedAt: Date?
    @Published private(set) var finishedAt: Date?
    @Published private(set) var phase: BuildExecutionPhase = .idle
    @Published private(set) var lastError: BuildWorkspaceError?
    @Published private(set) var lastExitCode: Int32?
    @Published private(set) var processID: Int32?
    @Published private(set) var terminationReason = ""
    @Published private(set) var currentInvocation: BuildInvocation?

    private var process: Process?
    private var stdoutHandle: FileHandle?
    private var stderrHandle: FileHandle?
    private var wasCancelled = false
    private var cancellationReason = ""
    private var sleepActivityToken: NSObjectProtocol?
    private var timeoutWorkItem: DispatchWorkItem?
    private var stdoutBuffer = Data()
    private var stderrBuffer = Data()
    private var currentRunID: UUID?
    private var currentLogSessionID: UUID?

    var isRunning: Bool { phase.isActive }
    var hasOutput: Bool { !logLines.isEmpty }

    var duration: TimeInterval {
        guard let startedAt else { return 0 }
        return (finishedAt ?? Date()).timeIntervalSince(startedAt)
    }

    @discardableResult
    func start(
        script: BuildScript,
        parameters: BuildParameterValues = [:],
        repository: Repository,
        historyStore: BuildHistoryStore,
        preferences: Preferences
    ) -> Bool {
        do {
            let invocation = try BuildCommandBuilder.invocation(for: script, values: parameters)
            DiagnosticsLog.write(
                .debug,
                "Starting \(script.fileName) in \(repository.name): \(invocation.commandPreview)",
                preferences: preferences
            )
            return start(invocation: invocation, repository: repository, historyStore: historyStore, preferences: preferences)
        } catch let error as BuildWorkspaceError {
            DiagnosticsLog.write(.error, "Validation failed for \(script.fileName): \(error.errorDescription ?? "unknown")", preferences: preferences)
            lastError = error
            return false
        } catch {
            DiagnosticsLog.write(.error, "Could not build an invocation for \(script.fileName): \(error.localizedDescription)", preferences: preferences)
            lastError = .validation(error.localizedDescription)
            return false
        }
    }

    @discardableResult
    func start(
        invocation: BuildInvocation,
        repository: Repository,
        historyStore: BuildHistoryStore,
        preferences: Preferences
    ) -> Bool {
        guard !isRunning else {
            lastError = .execution("A build is already running for this repository.")
            return false
        }
        guard case .local(let repositoryPath) = repository.source else {
            lastError = .validation("Clone this GitHub repository locally before running a build.")
            return false
        }
        guard invocation.script.location.isRunnable else {
            lastError = .validation("This script is \(invocation.script.location.label.lowercased()) and cannot be run.")
            return false
        }
        guard invocation.script.location != .outsideRepository || preferences.allowScriptsOutsideBuildScripts else {
            lastError = .validation("Scripts outside the repository are disabled in Preferences.")
            return false
        }
        guard FileManager.default.fileExists(atPath: invocation.script.path) else {
            lastError = .validation("The selected build script no longer exists on disk.")
            return false
        }
        guard FileManager.default.isReadableFile(atPath: invocation.script.path) else {
            lastError = .execution("The selected build script is not readable.")
            return false
        }

        logLines = []
        runningScript = invocation.script
        currentInvocation = invocation
        startedAt = Date()
        finishedAt = nil
        phase = .starting
        lastError = nil
        lastExitCode = nil
        processID = nil
        terminationReason = ""
        wasCancelled = false
        cancellationReason = ""
        currentRunID = UUID()
        currentLogSessionID = UUID()
        stdoutBuffer.removeAll(keepingCapacity: true)
        stderrBuffer.removeAll(keepingCapacity: true)
        appendSystem("Starting \(invocation.script.fileName)")
        appendSystem("Command: \(invocation.commandPreview)")
        appendSystem("Working directory: \(workingDirectoryURL(for: repositoryPath, preferences: preferences).path)")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: preferences.defaultShell)
        process.arguments = [invocation.script.path] + invocation.arguments
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
            self?.handleOutput(handle.availableData, stream: .stdout)
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            self?.handleOutput(handle.availableData, stream: .stderr)
        }

        process.terminationHandler = { [weak self] process in
            Task { @MainActor in
                self?.finish(
                    exitCode: process.terminationStatus,
                    processTerminationReason: process.terminationReason,
                    repository: repository,
                    script: invocation.script,
                    historyStore: historyStore,
                    preferences: preferences
                )
            }
        }

        self.process = process
        stdoutHandle = stdoutPipe.fileHandleForReading
        stderrHandle = stderrPipe.fileHandleForReading

        if preferences.preventSleepDuringBuild {
            sleepActivityToken = ProcessInfo.processInfo.beginActivity(
                options: [.idleSystemSleepDisabled],
                reason: "LXC-BRM build running: \(invocation.script.label)"
            )
        }

        BuildNotificationService.shared.notify(
            .started,
            repository: repository,
            script: invocation.script,
            preferences: preferences
        )

        do {
            try process.run()
            processID = process.processIdentifier
            phase = .running
            scheduleTimeout(preferences: preferences)
            return true
        } catch {
            lastError = .execution("Failed to start: \(error.localizedDescription)")
            appendSystem(lastError?.errorDescription ?? "Failed to start the build process.")
            finish(
                exitCode: -1,
                processTerminationReason: nil,
                repository: repository,
                script: invocation.script,
                historyStore: historyStore,
                preferences: preferences
            )
            return false
        }
    }

    func cancel(preferences: Preferences, reason: String = "Stopped by user") {
        DiagnosticsLog.write(.info, "Stop requested: \(reason)", preferences: preferences)
        guard let process, isRunning else { return }
        wasCancelled = true
        cancellationReason = reason
        phase = .stopping
        appendSystem("Stop requested: \(reason).")
        if preferences.terminateChildProcessesOnStop {
            Self.killProcessTree(rootPID: process.processIdentifier)
        } else {
            process.terminate()
        }
    }

    func clearOutput() {
        logLines.removeAll(keepingCapacity: true)
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
            self.cancel(preferences: preferences, reason: "Timed out after \(effectiveMinutes) minute(s)")
        }
        timeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(effectiveMinutes * 60), execute: workItem)
    }

    private enum OutputStream {
        case stdout
        case stderr

        var logStream: LogStream {
            switch self {
            case .stdout: return .stdout
            case .stderr: return .stderr
            }
        }
    }

    nonisolated private func handleOutput(_ data: Data, stream: OutputStream) {
        guard !data.isEmpty else { return }
        Task { @MainActor [weak self] in
            self?.appendOutput(data, from: stream)
        }
    }

    private func appendOutput(_ data: Data, from stream: OutputStream) {
        var buffer = stream == .stdout ? stdoutBuffer : stderrBuffer
        buffer.append(data)

        while let newline = buffer.firstIndex(of: 0x0A) {
            let lineData = buffer[..<newline]
            let line = String(decoding: lineData.last == 0x0D ? lineData.dropLast() : lineData, as: UTF8.self)
            logLines.append(LogLine(timestamp: Date(), text: line, stream: stream.logStream))
            buffer.removeSubrange(...newline)
        }

        switch stream {
        case .stdout: stdoutBuffer = buffer
        case .stderr: stderrBuffer = buffer
        }
    }

    private func flushOutputBuffers() {
        if !stdoutBuffer.isEmpty {
            let line = String(decoding: stdoutBuffer.last == 0x0D ? stdoutBuffer.dropLast() : stdoutBuffer, as: UTF8.self)
            logLines.append(LogLine(timestamp: Date(), text: line, stream: .stdout))
        }
        if !stderrBuffer.isEmpty {
            let line = String(decoding: stderrBuffer.last == 0x0D ? stderrBuffer.dropLast() : stderrBuffer, as: UTF8.self)
            logLines.append(LogLine(timestamp: Date(), text: line, stream: .stderr))
        }
        stdoutBuffer.removeAll(keepingCapacity: true)
        stderrBuffer.removeAll(keepingCapacity: true)
    }

    private func appendSystem(_ text: String) {
        logLines.append(LogLine(timestamp: Date(), text: text, stream: .system))
    }

    private func finish(
        exitCode: Int32,
        processTerminationReason: Process.TerminationReason?,
        repository: Repository,
        script: BuildScript,
        historyStore: BuildHistoryStore,
        preferences: Preferences
    ) {
        guard runningScript != nil else { return }
        stdoutHandle?.readabilityHandler = nil
        stderrHandle?.readabilityHandler = nil
        flushOutputBuffers()
        finishedAt = Date()
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil

        if let token = sleepActivityToken {
            ProcessInfo.processInfo.endActivity(token)
            sleepActivityToken = nil
        }

        let finalStatus: BuildStatus = wasCancelled ? .cancelled : (exitCode == 0 ? .success : .failed)
        let resolvedTerminationReason: String = {
            if wasCancelled { return cancellationReason.isEmpty ? "Cancelled" : cancellationReason }
            if processTerminationReason == .uncaughtSignal { return "Terminated by signal" }
            return exitCode == 0 ? "Completed successfully" : "Exited with code \(exitCode)"
        }()
        terminationReason = resolvedTerminationReason
        lastExitCode = exitCode
        switch finalStatus {
        case .success: phase = .succeeded
        case .failed: phase = .failed
        case .cancelled: phase = .cancelled
        case .running: phase = .running
        }
        appendSystem("Build \(statusText(finalStatus)): \(resolvedTerminationReason) in \(durationDescription(duration)).")

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
                id: currentRunID ?? UUID(),
                logSessionID: currentLogSessionID ?? UUID(),
                repositoryID: repository.id,
                scriptFileName: script.fileName,
                scriptLabel: script.label,
                startedAt: startedAt ?? Date(),
                status: finalStatus,
                durationSeconds: duration,
                logFileName: logFileName,
                processID: processID,
                exitCode: exitCode,
                terminationReason: resolvedTerminationReason,
                parameterValues: currentInvocation?.parameterValues ?? [:]
            )
        )

        let notificationKind: BuildNotificationService.Kind = {
            switch finalStatus {
            case .success: return .succeeded
            case .failed: return .failed
            case .cancelled: return .cancelled
            case .running: return .started
            }
        }()
        BuildNotificationService.shared.notify(notificationKind, repository: repository, script: script, preferences: preferences)

        runningScript = nil
        process = nil
        processID = nil
        currentInvocation = nil
        currentRunID = nil
        currentLogSessionID = nil
        wasCancelled = false
        cancellationReason = ""
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

    private func statusText(_ status: BuildStatus) -> String {
        switch status {
        case .success: return "succeeded"
        case .failed: return "failed"
        case .cancelled: return "cancelled"
        case .running: return "running"
        }
    }

    private func durationDescription(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainder = Int(seconds) % 60
        return minutes > 0 ? "\(minutes)m \(remainder)s" : "\(remainder)s"
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

    func cancelAll(preferences: Preferences) {
        for runner in runners.values where runner.isRunning {
            runner.cancel(preferences: preferences, reason: "Application is closing")
        }
    }
}
