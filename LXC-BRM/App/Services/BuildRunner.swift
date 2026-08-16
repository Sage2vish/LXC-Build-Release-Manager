import Foundation

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

    var isRunning: Bool { runningScript != nil }

    var duration: TimeInterval {
        guard let startedAt else { return 0 }
        return (finishedAt ?? Date()).timeIntervalSince(startedAt)
    }

    func start(script: BuildScript, repository: Repository, historyStore: BuildHistoryStore) {
        guard !isRunning, case .local(let repositoryPath) = repository.source else { return }

        logLines = []
        runningScript = script
        startedAt = Date()
        finishedAt = nil
        wasCancelled = false

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [script.path]
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

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
                self?.finish(exitCode: proc.terminationStatus, repository: repository, script: script, historyStore: historyStore)
            }
        }

        self.process = process
        stdoutHandle = stdoutPipe.fileHandleForReading
        stderrHandle = stderrPipe.fileHandleForReading

        do {
            try process.run()
        } catch {
            logLines.append(LogLine(timestamp: Date(), text: "Failed to start: \(error.localizedDescription)"))
            finish(exitCode: -1, repository: repository, script: script, historyStore: historyStore)
        }
    }

    func cancel() {
        guard let process, isRunning else { return }
        wasCancelled = true
        process.terminate()
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

    private func finish(exitCode: Int32, repository: Repository, script: BuildScript, historyStore: BuildHistoryStore) {
        guard runningScript != nil else { return }
        stdoutHandle?.readabilityHandler = nil
        stderrHandle?.readabilityHandler = nil
        finishedAt = Date()

        let finalStatus: BuildStatus = wasCancelled ? .cancelled : (exitCode == 0 ? .success : .failed)
        let logFileName = LogFileService.write(
            lines: logLines,
            repository: repository,
            script: script,
            status: finalStatus,
            startedAt: startedAt ?? Date()
        )

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

        runningScript = nil
        process = nil
        wasCancelled = false
    }
}

@MainActor
final class BuildRunnerRegistry: ObservableObject {
    private var runners: [UUID: BuildRunner] = [:]

    func runner(for repositoryID: UUID) -> BuildRunner {
        if let existing = runners[repositoryID] { return existing }
        let runner = BuildRunner()
        runners[repositoryID] = runner
        return runner
    }
}
