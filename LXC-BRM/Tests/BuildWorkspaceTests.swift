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

    // MARK: Folder import — the branches the GUI could not be driven through

    func testFolderImportRejectsFolderOutsideTheRepository() throws {
        let repository = temporaryDirectory.appendingPathComponent("ImportRepo", isDirectory: true)
        let outside = temporaryDirectory.appendingPathComponent("SomewhereElse", isDirectory: true)
        try FileManager.default.createDirectory(at: repository, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: outside, withIntermediateDirectories: true)
        try "echo hi".write(to: outside.appendingPathComponent("outside.sh"), atomically: true, encoding: .utf8)

        let blocked = BuildScriptFolderImport.resolve(
            folderPath: outside.path,
            repositoryPath: repository.path,
            allowOutsideRepository: false,
            existingPaths: []
        )
        XCTAssertEqual(blocked, .outsideRepository)
        XCTAssertEqual(
            blocked.errorMessage,
            "That folder is outside this repository. Enable that option in Preferences to add it."
        )

        // The same folder is allowed once the preference opts in.
        let allowed = BuildScriptFolderImport.resolve(
            folderPath: outside.path,
            repositoryPath: repository.path,
            allowOutsideRepository: true,
            existingPaths: []
        )
        XCTAssertEqual(allowed, .scripts([outside.appendingPathComponent("outside.sh").path]))
    }

    func testFolderImportReportsEmptyUnreadableAndFullyDuplicateFolders() throws {
        let repository = temporaryDirectory.appendingPathComponent("DupRepo", isDirectory: true)
        let empty = repository.appendingPathComponent("empty", isDirectory: true)
        let scripts = repository.appendingPathComponent("scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: scripts, withIntermediateDirectories: true)
        try "not a script".write(to: empty.appendingPathComponent("readme.txt"), atomically: true, encoding: .utf8)

        let first = scripts.appendingPathComponent("a.sh")
        let second = scripts.appendingPathComponent("b.sh")
        try "echo a".write(to: first, atomically: true, encoding: .utf8)
        try "echo b".write(to: second, atomically: true, encoding: .utf8)

        func resolve(_ folder: URL, existing: Set<String> = []) -> BuildScriptFolderImport.Outcome {
            BuildScriptFolderImport.resolve(
                folderPath: folder.path,
                repositoryPath: repository.path,
                allowOutsideRepository: false,
                existingPaths: existing
            )
        }

        XCTAssertEqual(resolve(empty), .noScriptsInFolder)
        XCTAssertEqual(resolve(empty).errorMessage, "No .sh scripts were found in that folder.")

        XCTAssertEqual(
            resolve(repository.appendingPathComponent("does-not-exist")),
            .unreadableFolder
        )

        // Every script already present: nothing to add.
        XCTAssertEqual(
            resolve(scripts, existing: [first.path, second.path]),
            .allAlreadyAdded
        )
        XCTAssertEqual(
            resolve(scripts, existing: [first.path, second.path]).errorMessage,
            "Those scripts are already in this repository."
        )

        // Partially present: only the genuinely new script is returned.
        XCTAssertEqual(resolve(scripts, existing: [first.path]), .scripts([second.path]))
        // Nothing present: both, in sorted order.
        XCTAssertEqual(resolve(scripts), .scripts([first.path, second.path]))
    }

    // MARK: GitHub origin field

    func testGitHubURLValidatorAcceptsClearsAndRejects() {
        XCTAssertEqual(GitHubURLValidator.evaluate(""), .cleared)
        XCTAssertEqual(GitHubURLValidator.evaluate("   \n "), .cleared)

        XCTAssertEqual(
            GitHubURLValidator.evaluate("  https://github.com/Sage2vish/LXC-BRM  "),
            .valid("https://github.com/Sage2vish/LXC-BRM")
        )

        for rejected in [
            "https://gitlab.com/owner/repo",
            "https://github.com/owner",
            "not a url at all",
            "https://notgithub.com/owner/repo"
        ] {
            XCTAssertEqual(
                GitHubURLValidator.evaluate(rejected),
                .invalid(GitHubURLValidator.invalidMessage),
                "Expected \(rejected) to be rejected"
            )
        }
    }

    func testRepositoryKeepsGitHubURLOptionalAndDecodesOlderRecords() throws {
        // A repository written before the field existed must still decode.
        let legacy = """
        {"id":"\(UUID().uuidString)","name":"Legacy","source":{"local":{"_0":"/tmp/legacy"}},
         "lastAccessed":0,"isPinned":false}
        """
        let decoder = JSONDecoder()
        let restored = try? decoder.decode(Repository.self, from: Data(legacy.utf8))
        XCTAssertNil(restored?.gitHubURL)

        var repository = Repository(name: "Example", source: .local(path: "/tmp/example"))
        XCTAssertNil(repository.resolvedGitHubURL)
        repository.gitHubURL = "https://github.com/owner/repo"
        XCTAssertEqual(repository.resolvedGitHubURL, "https://github.com/owner/repo")
        XCTAssertEqual(repository.localPath, "/tmp/example")

        // A GitHub-sourced repository resolves its URL from `source` with no extra field.
        let remote = Repository(name: "Remote", source: .github(url: "https://github.com/owner/remote"))
        XCTAssertEqual(remote.resolvedGitHubURL, "https://github.com/owner/remote")
        XCTAssertNil(remote.localPath)
    }

    func testDeepScriptSearchSkipsXcodeBuildTreesButKeepsRealScripts() throws {
        let repository = temporaryDirectory.appendingPathComponent("SearchRepo", isDirectory: true)
        let keep = repository.appendingPathComponent("tools", isDirectory: true)
        let derived = repository.appendingPathComponent("DerivedData-Device-Release/Build", isDirectory: true)
        let intermediate = repository.appendingPathComponent("ios/hermes-engine.build", isDirectory: true)
        let modules = repository.appendingPathComponent("node_modules/pkg", isDirectory: true)
        for directory in [keep, derived, intermediate, modules] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try "echo real".write(to: keep.appendingPathComponent("deploy.sh"), atomically: true, encoding: .utf8)
        try "echo junk".write(to: derived.appendingPathComponent("Script-ABC123.sh"), atomically: true, encoding: .utf8)
        try "echo junk".write(to: intermediate.appendingPathComponent("Script-DEF456.sh"), atomically: true, encoding: .utf8)
        try "echo junk".write(to: modules.appendingPathComponent("postinstall.sh"), atomically: true, encoding: .utf8)

        let found = DeepScriptSearch.search(rootPath: repository.path, existingPaths: [])
        XCTAssertEqual(found.map(\.fileName), ["deploy.sh"])
        XCTAssertEqual(found.first?.folderName, "tools")
        XCTAssertEqual(found.first?.relativePath, "tools/deploy.sh")
        XCTAssertFalse(found.first?.isAlreadyAdded ?? true)

        let reRun = DeepScriptSearch.search(
            rootPath: repository.path,
            existingPaths: [keep.appendingPathComponent("deploy.sh").path]
        )
        XCTAssertTrue(reRun.first?.isAlreadyAdded ?? false)
    }

    // MARK: Log presentation

    func testLogPresentationStripsANSIAndPicksColours() {
        let red = LogPresentation.terminalPresentation(for: "\u{001B}[31mBuild failed\u{001B}[0m")
        XCTAssertEqual(red.text, "Build failed")
        XCTAssertEqual(red.ansiColor, .red)

        let bright = LogPresentation.terminalPresentation(for: "\u{001B}[92mok\u{001B}[0m")
        XCTAssertEqual(bright.ansiColor, .green)

        let plain = LogPresentation.terminalPresentation(for: "nothing special")
        XCTAssertEqual(plain.text, "nothing special")
        XCTAssertNil(plain.ansiColor)
    }

    func testLogPresentationRecoversStreamMarkersFromSavedLogs() {
        XCTAssertEqual(LogPresentation.streamPayload(from: "[stderr] boom").stream, .stderr)
        XCTAssertEqual(LogPresentation.streamPayload(from: "[stderr] boom").text, "boom")
        XCTAssertEqual(LogPresentation.streamPayload(from: "[system] note").stream, .system)
        XCTAssertEqual(LogPresentation.streamPayload(from: "ordinary").stream, .stdout)
    }

    func testLogPresentationParsesSavedFileContentAndDropsHeaderLines() {
        let content = """
        # Build log for release.sh
        # Started 2026-08-16

        [10:15:01] starting
        [10:15:02] [stderr] warning: something
        no timestamp here
        """
        let lines = LogPresentation.displayLines(fromFileContent: content)
        XCTAssertEqual(lines.count, 3)
        XCTAssertEqual(lines[0].timestampText, "10:15:01")
        XCTAssertEqual(lines[0].text, "starting")
        XCTAssertEqual(lines[1].stream, .stderr)
        XCTAssertEqual(lines[1].text, "warning: something")
        XCTAssertEqual(lines[2].timestampText, "")
        XCTAssertEqual(lines[2].text, "no timestamp here")
    }

    func testLogFilterAndSearchNarrowTheVisibleLines() {
        let lines = [
            DisplayLine(timestampText: "", text: "compiling main.swift", stream: .stdout, ansiColor: nil),
            DisplayLine(timestampText: "", text: "warning: deprecated API", stream: .stderr, ansiColor: nil),
            DisplayLine(timestampText: "", text: "error: build failed", stream: .stderr, ansiColor: nil)
        ]

        XCTAssertEqual(LogPresentation.visibleLines(lines, filter: .all, searchText: "", caseSensitive: false).count, 3)
        XCTAssertEqual(LogPresentation.visibleLines(lines, filter: .errors, searchText: "", caseSensitive: false).count, 1)
        XCTAssertEqual(LogPresentation.visibleLines(lines, filter: .warnings, searchText: "", caseSensitive: false).count, 1)
        // "info" excludes anything that reads as an error or a warning.
        XCTAssertEqual(LogPresentation.visibleLines(lines, filter: .info, searchText: "", caseSensitive: false).map(\.text), ["compiling main.swift"])

        XCTAssertEqual(LogPresentation.visibleLines(lines, filter: .all, searchText: "MAIN", caseSensitive: false).count, 1)
        XCTAssertEqual(LogPresentation.visibleLines(lines, filter: .all, searchText: "MAIN", caseSensitive: true).count, 0)
        // "compiling main.swift" has no "e"; the warning and error lines do.
        XCTAssertEqual(LogPresentation.matchCount(lines, searchText: "e", caseSensitive: false), 2)
        XCTAssertEqual(LogPresentation.matchCount(lines, searchText: "", caseSensitive: false), 0)
    }

    // MARK: Shared persistence boundary

    func testJSONFileStoreReportsMissingCorruptAndUnwritableCases() throws {
        struct Sample: Codable, Equatable { var name: String; var stamp: Date }

        // Missing file is a first launch, not an error.
        let missing = JSONFileStore(url: temporaryDirectory.appendingPathComponent("nope.json"))
        XCTAssertFalse(missing.exists)
        guard case .success(let none) = missing.load(Sample.self) else {
            return XCTFail("A missing file should not be an error")
        }
        XCTAssertNil(none)

        // Round trip preserves values and uses ISO-8601 dates on disk.
        let url = temporaryDirectory.appendingPathComponent("sample.json")
        let store = JSONFileStore(url: url)
        let value = Sample(name: "release", stamp: Date(timeIntervalSince1970: 1_700_000_000))
        guard case .success = store.save(value) else { return XCTFail("Save should succeed") }
        XCTAssertTrue(store.exists)
        let raw = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(raw.contains("2023-11-14T"), "Expected ISO-8601 date, got: \(raw)")
        guard case .success(let restored) = store.load(Sample.self) else {
            return XCTFail("Load should succeed")
        }
        XCTAssertEqual(restored, value)

        // Malformed JSON is reported rather than silently dropped.
        try "{ not json".write(to: url, atomically: true, encoding: .utf8)
        guard case .failure(let error) = store.load(Sample.self) else {
            return XCTFail("Corrupt JSON should surface an error")
        }
        guard case .corrupt(let file, _) = error else {
            return XCTFail("Expected .corrupt, got \(error)")
        }
        XCTAssertEqual(file, "sample.json")

        // A path that cannot be written reports .unwritable.
        let unwritable = JSONFileStore(url: URL(fileURLWithPath: "/no-such-dir-here/x.json"))
        guard case .failure(let writeError) = unwritable.save(value) else {
            return XCTFail("Writing into a missing directory should fail")
        }
        guard case .unwritable = writeError else {
            return XCTFail("Expected .unwritable, got \(writeError)")
        }
    }

    func testAppDataLocationsNamesEveryFileExactlyOnce() {
        let names = AppDataLocations.File.allCases.map(\.rawValue)
        XCTAssertEqual(Set(names).count, names.count, "Duplicate data file name")
        // These names are the on-disk contract; changing one strands existing installs.
        XCTAssertEqual(
            Set(names),
            [
                "projects.json",
                "selected-repository.json",
                "build-history.json",
                "preferences.json",
                "build-workspace-state.json"
            ]
        )
        XCTAssertTrue(
            AppDataLocations.url(for: .repositories).path.hasSuffix("LXC-BRM/projects.json")
        )
    }

    // MARK: Shared build presentation

    func testBuildPresentationFormatsDurationsAndStatuses() {
        XCTAssertEqual(BuildPresentation.durationDescription(0), "0s")
        XCTAssertEqual(BuildPresentation.durationDescription(45), "45s")
        XCTAssertEqual(BuildPresentation.durationDescription(60), "1m 0s")
        XCTAssertEqual(BuildPresentation.durationDescription(90), "1m 30s")
        XCTAssertEqual(BuildPresentation.durationDescription(3_661), "61m 1s")
        // A clock skew should not render "-1m -30s".
        XCTAssertEqual(BuildPresentation.durationDescription(-90), "0s")

        XCTAssertEqual(BuildPresentation.symbolName(for: .success), "checkmark.circle.fill")
        XCTAssertEqual(BuildPresentation.symbolName(for: .failed), "xmark.circle.fill")
        XCTAssertEqual(BuildPresentation.glyph(for: .success), "✓")
        XCTAssertEqual(BuildPresentation.glyph(for: .cancelled), "⊘")
        XCTAssertEqual(BuildPresentation.glyph(for: .failed), "✗")
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
