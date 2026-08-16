import Foundation
import XCTest
@testable import LXC_BRM

@MainActor
final class BuildWorkspaceTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LXC-BRM-Tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
    }

    func testPathResolverNormalizesAndRespectsRepositoryBoundary() {
        let repository = temporaryDirectory.appendingPathComponent("Repo", isDirectory: true)
        let script = repository.appendingPathComponent("build/scripts/build-ios.sh")
        let similarlyNamedFolder = temporaryDirectory.appendingPathComponent("Repo-copy/build/scripts/build-ios.sh")

        XCTAssertTrue(BuildScriptPathResolver.isWithin(script.path, rootPath: repository.path))
        XCTAssertFalse(BuildScriptPathResolver.isWithin(similarlyNamedFolder.path, rootPath: repository.path))
        XCTAssertTrue(BuildScriptPathResolver.pathsEqual("\(repository.path)/build/../build", "\(repository.path)/build"))
        XCTAssertFalse(BuildScriptPathResolver.pathsEqual("/tmp/Repo", "/tmp/repo", caseSensitive: true))
        XCTAssertTrue(BuildScriptPathResolver.pathsEqual("/tmp/Repo", "/tmp/repo", caseSensitive: false))
    }

    func testLocalDiscoveryClassifiesScriptsAndParsesParameters() throws {
        let repository = temporaryDirectory.appendingPathComponent("Example", isDirectory: true)
        let scriptsDirectory = repository.appendingPathComponent("build/scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: true)
        let scriptURL = scriptsDirectory.appendingPathComponent("build-ios.sh")
        let script = """
        #!/bin/zsh
        # lxc:label Build iOS App
        # lxc:param configuration type=choice options=Debug,Release default=Debug required=true
        # lxc:param coverage type=boolean default=false
        echo running
        """
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)

        let result = BuildScriptScanner.scanLocal(path: repository.path)
        guard case .success(let scripts) = result, let discovered = scripts.first else {
            return XCTFail("Expected the local script to be discovered")
        }
        XCTAssertEqual(discovered.label, "Build iOS App")
        XCTAssertEqual(discovered.location, .standardFolder)
        XCTAssertEqual(discovered.parameters.map(\.key), ["configuration", "coverage"])
        XCTAssertEqual(discovered.parameters.first?.kind, .choice)
    }

    func testCommandBuilderValidatesAndBuildsArgumentsOnce() throws {
        let script = BuildScript(
            fileName: "release.sh",
            label: "Release",
            path: "/tmp/release.sh",
            parameters: [
                BuildParameterDefinition(key: "version", kind: .text, isRequired: true),
                BuildParameterDefinition(key: "configuration", kind: .choice, options: ["Debug", "Release"], defaultValue: "Debug"),
                BuildParameterDefinition(key: "coverage", kind: .boolean, defaultValue: "false")
            ]
        )

        XCTAssertFalse(BuildCommandBuilder.validate(script: script, values: [:]).isEmpty)
        let invocation = try BuildCommandBuilder.invocation(
            for: script,
            values: ["version": "1.2.3", "configuration": "Release", "coverage": "true"]
        )
        XCTAssertEqual(invocation.arguments, ["--version", "1.2.3", "--configuration", "Release", "--coverage"])
        XCTAssertTrue(invocation.commandPreview.contains("--version 1.2.3"))
    }

    func testWorkspaceStatePersistsSelectionsParametersAndExtraScripts() {
        let stateURL = temporaryDirectory.appendingPathComponent("workspace-state.json")
        let repositoryID = UUID()
        let store = BuildWorkspaceStateStore(storeURL: stateURL)

        store.select(scriptID: "script-1", for: repositoryID)
        store.save(values: ["configuration": "Release"], for: "script-1", repositoryID: repositoryID)
        store.add(scriptPath: "/tmp/extra-build.sh", for: repositoryID)

        let restored = BuildWorkspaceStateStore(storeURL: stateURL)
        XCTAssertEqual(restored.state(for: repositoryID).selectedScriptID, "script-1")
        XCTAssertEqual(restored.values(for: "script-1", repositoryID: repositoryID)["configuration"], "Release")
        XCTAssertEqual(restored.state(for: repositoryID).addedScriptPaths, ["/tmp/extra-build.sh"])
    }

    func testRefreshKeepsStableIdentifiersAndReturnsEmptyStates() throws {
        let repository = temporaryDirectory.appendingPathComponent("RefreshRepo", isDirectory: true)
        let scriptsDirectory = repository.appendingPathComponent("build/scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: true)
        let scriptURL = scriptsDirectory.appendingPathComponent("refresh.sh")
        try "echo refresh".write(to: scriptURL, atomically: true, encoding: .utf8)

        let firstScan = BuildScriptScanner.scanLocal(path: repository.path)
        let secondScan = BuildScriptScanner.scanLocal(path: repository.path)
        guard case .success(let firstScripts) = firstScan,
              case .success(let secondScripts) = secondScan else {
            return XCTFail("Expected repeatable script discovery")
        }
        XCTAssertEqual(firstScripts.first?.id, secondScripts.first?.id)

        let emptyRepository = temporaryDirectory.appendingPathComponent("EmptyRepo", isDirectory: true)
        try FileManager.default.createDirectory(at: emptyRepository.appendingPathComponent("build/scripts"), withIntermediateDirectories: true)
        XCTAssertEqual(BuildScriptScanner.scanLocal(path: emptyRepository.path), .emptyScripts)
        XCTAssertEqual(BuildScriptScanner.scanLocal(path: temporaryDirectory.appendingPathComponent("MissingRepo").path), .missingBuildFolder)
    }

    func testClearOutputDoesNotEraseHistoryAndSaveLogKeepsStreamMarkers() async throws {
        let repositoryURL = temporaryDirectory.appendingPathComponent("ClearRepo", isDirectory: true)
        let scriptsDirectory = repositoryURL.appendingPathComponent("build/scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: true)
        let scriptURL = scriptsDirectory.appendingPathComponent("clear.sh")
        try "echo output; echo error >&2".write(to: scriptURL, atomically: true, encoding: .utf8)

        let script = BuildScript(fileName: "clear.sh", label: "Clear", path: scriptURL.path)
        let repository = Repository(name: "ClearRepo", source: .local(path: repositoryURL.path))
        let history = BuildHistoryStore(storeURL: temporaryDirectory.appendingPathComponent("history.json"))
        let runner = BuildRunner()
        var preferences = Preferences()
        preferences.automaticallySaveLogs = false
        preferences.saveLogsAutomatically = false
        preferences.enableBuildNotifications = false
        preferences.preventSleepDuringBuild = false
        preferences.buildTimeoutMinutes = 0

        XCTAssertTrue(runner.start(script: script, repository: repository, historyStore: history, preferences: preferences))
        try await waitForRunner(runner)
        let content = LogFileService.formattedContent(lines: runner.logLines, script: script, status: .success, startedAt: Date())
        XCTAssertTrue(content.contains("[stderr] error"))
        let fileName = LogFileService.write(lines: runner.logLines, repository: repository, script: script, status: .success, startedAt: Date())
        XCTAssertFalse(LogFileService.read(fileName: fileName, repository: repository)?.isEmpty ?? true)

        runner.clearOutput()
        XCTAssertTrue(runner.logLines.isEmpty)
        XCTAssertEqual(history.records(for: repository.id).count, 1)
    }

    func testBuildRecordPersistsParameterMetadata() throws {
        let record = BuildRecord(
            repositoryID: UUID(),
            scriptFileName: "release.sh",
            scriptLabel: "Release",
            startedAt: Date(),
            status: .success,
            durationSeconds: 2,
            logFileName: "build.log",
            exitCode: 0,
            terminationReason: "Completed successfully",
            parameterValues: ["version": "1.2.3"]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let restored = try decoder.decode(BuildRecord.self, from: encoder.encode(record))
        XCTAssertEqual(restored.parameterValues, ["version": "1.2.3"])
        XCTAssertEqual(restored.logSessionID, record.logSessionID)
    }

    func testRunnerStreamsOutputAndRecordsCompletion() async throws {
        let repositoryURL = temporaryDirectory.appendingPathComponent("RunnerRepo", isDirectory: true)
        let scriptsDirectory = repositoryURL.appendingPathComponent("build/scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: true)
        let scriptURL = scriptsDirectory.appendingPathComponent("stream.sh")
        try "echo ready; echo warning >&2; sleep 0.1; echo done".write(to: scriptURL, atomically: true, encoding: .utf8)

        let script = BuildScript(fileName: "stream.sh", label: "Stream", path: scriptURL.path)
        let repository = Repository(name: "RunnerRepo", source: .local(path: repositoryURL.path))
        let history = BuildHistoryStore(storeURL: temporaryDirectory.appendingPathComponent("history.json"))
        let runner = BuildRunner()
        var preferences = Preferences()
        preferences.automaticallySaveLogs = false
        preferences.saveLogsAutomatically = false
        preferences.enableBuildNotifications = false
        preferences.preventSleepDuringBuild = false
        preferences.buildTimeoutMinutes = 0

        XCTAssertTrue(runner.start(script: script, repository: repository, historyStore: history, preferences: preferences))
        try await waitForRunner(runner)

        XCTAssertEqual(runner.phase, .succeeded)
        XCTAssertTrue(runner.logLines.contains { $0.text == "ready" && $0.stream == .stdout })
        XCTAssertTrue(runner.logLines.contains { $0.text == "warning" && $0.stream == .stderr })
        XCTAssertEqual(history.records(for: repository.id).first?.status, .success)
        XCTAssertEqual(history.records(for: repository.id).first?.exitCode, 0)
        XCTAssertNotNil(history.records(for: repository.id).first?.processID)
    }

    func testRunnerStopTransitionsToCancelledAndPreservesReason() async throws {
        let repositoryURL = temporaryDirectory.appendingPathComponent("StopRepo", isDirectory: true)
        let scriptsDirectory = repositoryURL.appendingPathComponent("build/scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: true)
        let scriptURL = scriptsDirectory.appendingPathComponent("slow.sh")
        try "echo started; sleep 5".write(to: scriptURL, atomically: true, encoding: .utf8)

        let script = BuildScript(fileName: "slow.sh", label: "Slow", path: scriptURL.path)
        let repository = Repository(name: "StopRepo", source: .local(path: repositoryURL.path))
        let history = BuildHistoryStore(storeURL: temporaryDirectory.appendingPathComponent("history.json"))
        let runner = BuildRunner()
        var preferences = Preferences()
        preferences.automaticallySaveLogs = false
        preferences.saveLogsAutomatically = false
        preferences.enableBuildNotifications = false
        preferences.preventSleepDuringBuild = false
        preferences.buildTimeoutMinutes = 0

        XCTAssertTrue(runner.start(script: script, repository: repository, historyStore: history, preferences: preferences))
        try await Task.sleep(for: .milliseconds(120))
        runner.cancel(preferences: preferences)
        try await waitForRunner(runner)

        XCTAssertEqual(runner.phase, .cancelled)
        XCTAssertEqual(runner.terminationReason, "Stopped by user")
        XCTAssertTrue(runner.logLines.contains { $0.text.contains("Stop requested") })
        XCTAssertEqual(history.records(for: repository.id).first?.status, .cancelled)
    }

    private func waitForRunner(_ runner: BuildRunner, timeout: Duration = .seconds(5)) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        while runner.isRunning && clock.now < deadline {
            try await Task.sleep(for: .milliseconds(25))
        }
        XCTAssertFalse(runner.isRunning, "Build runner did not finish before the test timeout")
    }
}
