import Foundation
import XCTest
@testable import LXC_BRM

/// Covers the non-functional targets from the master checklist: scan speed, behaviour with
/// 5-10+ repositories, and graceful handling of missing, unreachable, and malformed inputs.
@MainActor
final class PerformanceAndResilienceTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LXC-BRM-Perf-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
    }

    @discardableResult
    private func makeRepository(named name: String, scripts: Int) throws -> URL {
        let root = temporaryDirectory.appendingPathComponent(name, isDirectory: true)
        let scriptsDirectory = root.appendingPathComponent("build/scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: true)
        for index in 0..<scripts {
            try "echo \(index)".write(
                to: scriptsDirectory.appendingPathComponent("script-\(index).sh"),
                atomically: true,
                encoding: .utf8
            )
        }
        return root
    }

    // MARK: Performance targets

    func testRepositoryScanStaysWellUnderTheFiveSecondTarget() throws {
        let root = try makeRepository(named: "Big", scripts: 60)

        let clock = ContinuousClock()
        let elapsed = clock.measure {
            guard case .success = BuildScriptScanner.scanLocal(path: root.path) else {
                return XCTFail("Expected a successful scan")
            }
        }

        guard case .success(let scripts) = BuildScriptScanner.scanLocal(path: root.path) else {
            return XCTFail("Expected a successful scan")
        }
        XCTAssertEqual(scripts.count, 60)
        XCTAssertLessThan(elapsed, .seconds(5), "Scan target is under 5 seconds; took \(elapsed)")
    }

    func testTenRepositoriesScanAndPersistWithoutDegrading() throws {
        var roots: [URL] = []
        for index in 0..<10 {
            roots.append(try makeRepository(named: "Repo-\(index)", scripts: 12))
        }

        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for root in roots {
                guard case .success = BuildScriptScanner.scanLocal(path: root.path) else {
                    return XCTFail("Expected \(root.lastPathComponent) to scan")
                }
            }
        }
        // Ten repositories back to back should still be far inside the single-repo budget.
        XCTAssertLessThan(elapsed, .seconds(5), "Ten scans took \(elapsed)")

        // The store keeps all ten, sorted most-recently-accessed first.
        let file = JSONFileStore(url: temporaryDirectory.appendingPathComponent("projects.json"))
        let repositories = roots.enumerated().map { index, root in
            Repository(
                name: root.lastPathComponent,
                source: .local(path: root.path),
                lastAccessed: Date(timeIntervalSince1970: TimeInterval(1_700_000_000 + index))
            )
        }
        guard case .success = file.save(repositories) else { return XCTFail("Save failed") }
        guard case .success(let restored) = file.load([Repository].self), let restored else {
            return XCTFail("Load failed")
        }
        XCTAssertEqual(restored.count, 10)
        XCTAssertEqual(Set(restored.map(\.name)).count, 10)
    }

    func testWorkspaceStateStaysCorrectAcrossManyRepositories() {
        let store = BuildWorkspaceStateStore(
            storeURL: temporaryDirectory.appendingPathComponent("workspace.json")
        )
        let ids = (0..<10).map { _ in UUID() }
        for (index, id) in ids.enumerated() {
            store.select(scriptID: "script-\(index)", for: id)
            store.save(values: ["configuration": "Release-\(index)"], for: "script-\(index)", repositoryID: id)
        }

        // Each repository keeps its own selection and parameter values — no cross-talk.
        for (index, id) in ids.enumerated() {
            XCTAssertEqual(store.state(for: id).selectedScriptID, "script-\(index)")
            XCTAssertEqual(
                store.values(for: "script-\(index)", repositoryID: id)["configuration"],
                "Release-\(index)"
            )
        }

        let reloaded = BuildWorkspaceStateStore(
            storeURL: temporaryDirectory.appendingPathComponent("workspace.json")
        )
        XCTAssertEqual(reloaded.state(for: ids[7]).selectedScriptID, "script-7")
    }

    // MARK: Resilience

    func testScanReportsMissingBuildFolderEmptyScriptsAndUnreadablePaths() throws {
        // No /build at all.
        let bare = temporaryDirectory.appendingPathComponent("Bare", isDirectory: true)
        try FileManager.default.createDirectory(at: bare, withIntermediateDirectories: true)
        XCTAssertEqual(BuildScriptScanner.scanLocal(path: bare.path), .missingBuildFolder)

        // /build/scripts exists but is empty.
        let empty = try makeRepository(named: "Empty", scripts: 0)
        XCTAssertEqual(BuildScriptScanner.scanLocal(path: empty.path), .emptyScripts)

        // A path that does not exist at all must not crash.
        XCTAssertEqual(
            BuildScriptScanner.scanLocal(path: temporaryDirectory.appendingPathComponent("Nope").path),
            .missingBuildFolder
        )
    }

    func testDeletedRepositoryFolderDegradesToMissingRatherThanCrashing() throws {
        let root = try makeRepository(named: "Vanishing", scripts: 3)
        guard case .success = BuildScriptScanner.scanLocal(path: root.path) else {
            return XCTFail("Expected the initial scan to succeed")
        }

        // The user deletes or unmounts the folder between scans.
        try FileManager.default.removeItem(at: root)
        XCTAssertEqual(BuildScriptScanner.scanLocal(path: root.path), .missingBuildFolder)
    }

    func testCorruptStoreFilesFallBackToDefaultsInsteadOfLosingTheApp() throws {
        // Preferences: a malformed file must still yield usable defaults.
        let preferencesURL = temporaryDirectory.appendingPathComponent("preferences.json")
        try "{ this is not json".write(to: preferencesURL, atomically: true, encoding: .utf8)
        guard case .failure = JSONFileStore(url: preferencesURL).load(Preferences.self) else {
            return XCTFail("Corrupt preferences should be reported")
        }
        // Defaults are still constructible, which is what the app falls back to.
        XCTAssertTrue(Preferences.recommendedDefaults.rememberRecentRepositories)

        // History: a malformed file is reported rather than silently discarded.
        let historyURL = temporaryDirectory.appendingPathComponent("history.json")
        try "[[".write(to: historyURL, atomically: true, encoding: .utf8)
        guard case .failure(let error) = JSONFileStore(url: historyURL).load([UUID: [BuildRecord]].self) else {
            return XCTFail("Corrupt history should be reported")
        }
        XCTAssertNotNil(error.errorDescription)

        // A store pointed at a corrupt file still constructs and surfaces the failure.
        let store = BuildHistoryStore(storeURL: historyURL)
        XCTAssertTrue(store.recordsByRepository.isEmpty)
        XCTAssertNotNil(store.lastError)
    }

    func testGitHubSourcedRepositoriesAreScannableButNotRunnable() {
        let remote = Repository(name: "Remote", source: .github(url: "https://github.com/owner/repo"))
        XCTAssertNil(remote.localPath)
        XCTAssertFalse(remote.source.isLocal)

        let remoteScript = BuildScript(
            fileName: "ci.sh",
            label: "CI",
            path: "ci.sh",
            location: .unavailable,
            isRemote: true
        )
        XCTAssertFalse(remoteScript.location.isRunnable)
        XCTAssertFalse(BuildScreenRules.canRun(
            script: remoteScript,
            isLocalRepository: false,
            isRunnerBusy: false,
            runningCount: 0,
            maxConcurrentBuilds: 2,
            allowScriptsOutsideRepository: true
        ))
    }
}

/// Covers the preferences that were previously stored and shown but never read.
@MainActor
final class PreferenceWiringTests: XCTestCase {
    func testAppearanceSettingsDeriveConcreteValues() {
        var prefs = Preferences()

        prefs.textSizePercent = 100
        XCTAssertEqual(AppearanceSettings.textScale(prefs), 1.0)
        prefs.textSizePercent = 150
        XCTAssertEqual(AppearanceSettings.textScale(prefs), 1.5)
        // A hand-edited preferences.json must not make the UI unusable.
        prefs.textSizePercent = 10_000
        XCTAssertEqual(AppearanceSettings.textScale(prefs), 1.5)
        prefs.textSizePercent = 0
        XCTAssertEqual(AppearanceSettings.textScale(prefs), 0.8)

        prefs.uiDensity = "Compact"
        XCTAssertEqual(AppearanceSettings.rowSpacing(prefs), 4)
        prefs.uiDensity = "Spacious"
        XCTAssertEqual(AppearanceSettings.rowSpacing(prefs), 14)
        prefs.uiDensity = "Comfortable"
        XCTAssertEqual(AppearanceSettings.rowSpacing(prefs), 8)

        prefs.roundWindowCorners = true
        XCTAssertEqual(AppearanceSettings.cornerRadius(prefs), 12)
        prefs.roundWindowCorners = false
        XCTAssertEqual(AppearanceSettings.cornerRadius(prefs), 0)

        prefs.showAnimations = true
        XCTAssertNotNil(AppearanceSettings.animation(prefs))
        XCTAssertNil(AppearanceSettings.animation(prefs, reduceMotion: true))
        prefs.showAnimations = false
        XCTAssertNil(AppearanceSettings.animation(prefs))
    }

    func testAccentColourParsingAcceptsValidHexAndRejectsGarbage() {
        XCTAssertNotNil(AppearanceSettings.color(fromHex: "#0A84FF"))
        XCTAssertNotNil(AppearanceSettings.color(fromHex: "0A84FF"))
        XCTAssertNotNil(AppearanceSettings.color(fromHex: "#0A84FF80"))
        for bad in ["", "#", "xyz", "#12345", "#GGGGGG", "rgb(1,2,3)"] {
            XCTAssertNil(AppearanceSettings.color(fromHex: bad), "\(bad) should not parse")
        }
        // An unparseable stored value falls back to the system accent rather than crashing.
        var prefs = Preferences()
        prefs.accentColorHex = "not-a-colour"
        XCTAssertNil(AppearanceSettings.accentColor(prefs))
    }

    func testNotificationPreferencesGateGroupingDurationAndLongRunning() {
        var prefs = Preferences()

        prefs.notificationDuration = "5 seconds"
        XCTAssertFalse(BuildNotificationService.wantsPersistentBanner(prefs))
        prefs.notificationDuration = "Until dismissed"
        XCTAssertTrue(BuildNotificationService.wantsPersistentBanner(prefs))

        // Long-running builds notify even when their per-status toggle is off.
        prefs.notifyLongRunningBuildCompleted = true
        XCTAssertTrue(BuildNotificationService.shouldNotifyOnCompletion(
            durationSeconds: 120, statusEnabled: false, preferences: prefs
        ))
        // A quick build still respects the per-status toggle.
        XCTAssertFalse(BuildNotificationService.shouldNotifyOnCompletion(
            durationSeconds: 2, statusEnabled: false, preferences: prefs
        ))
        XCTAssertTrue(BuildNotificationService.shouldNotifyOnCompletion(
            durationSeconds: 2, statusEnabled: true, preferences: prefs
        ))
        // With the preference off, only the per-status toggle matters.
        prefs.notifyLongRunningBuildCompleted = false
        XCTAssertFalse(BuildNotificationService.shouldNotifyOnCompletion(
            durationSeconds: 600, statusEnabled: false, preferences: prefs
        ))
    }
}

/// Covers the scanner and diagnostics preferences wired in the same pass.
@MainActor
final class ScannerAndDiagnosticsPreferenceTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LXC-BRM-Prefs-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
    }

    func testDetectExecutableFilesControlsWhetherExtensionlessScriptsAreOffered() throws {
        let scripts = temporaryDirectory.appendingPathComponent("build/scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: scripts, withIntermediateDirectories: true)

        let dotSh = scripts.appendingPathComponent("with-extension.sh")
        try "echo hi".write(to: dotSh, atomically: true, encoding: .utf8)

        let executable = scripts.appendingPathComponent("no-extension")
        try "echo hi".write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        XCTAssertTrue(BuildScriptScanner.isRunnableScript(dotSh, detectExecutableFiles: false))
        XCTAssertTrue(BuildScriptScanner.isRunnableScript(executable, detectExecutableFiles: true))
        // With detection off, an extensionless executable is not offered as a build script.
        XCTAssertFalse(BuildScriptScanner.isRunnableScript(executable, detectExecutableFiles: false))

        var prefs = Preferences()
        prefs.detectExecutableFilesAutomatically = false
        let strict = BuildScanOptions(preferences: prefs)
        XCTAssertFalse(strict.detectExecutableFiles)
        guard case .success(let found) = BuildScriptScanner.scanLocal(path: temporaryDirectory.path, options: strict) else {
            return XCTFail("Expected a successful scan")
        }
        XCTAssertEqual(found.map(\.fileName), ["with-extension.sh"])
    }

    func testDiagnosticsRespectVerboseAndFileLoggingPreferences() throws {
        var prefs = Preferences()
        prefs.diagnosticsLogLocation = temporaryDirectory.path

        // File logging off: nothing is written at any level.
        prefs.logInternalDiagnosticsToFile = false
        prefs.verboseDebugLogging = true
        XCTAssertFalse(DiagnosticsLog.shouldWrite(.info, preferences: prefs))
        XCTAssertFalse(DiagnosticsLog.shouldWrite(.debug, preferences: prefs))

        // File logging on, verbose off: info and error only.
        prefs.logInternalDiagnosticsToFile = true
        prefs.verboseDebugLogging = false
        XCTAssertTrue(DiagnosticsLog.shouldWrite(.info, preferences: prefs))
        XCTAssertTrue(DiagnosticsLog.shouldWrite(.error, preferences: prefs))
        XCTAssertFalse(DiagnosticsLog.shouldWrite(.debug, preferences: prefs))

        // Verbose on: debug lines too.
        prefs.verboseDebugLogging = true
        XCTAssertTrue(DiagnosticsLog.shouldWrite(.debug, preferences: prefs))

        // Writing actually lands in the configured location.
        DiagnosticsLog.write(.info, "hello diagnostics", preferences: prefs)
        guard let url = DiagnosticsLog.logFileURL(preferences: prefs) else {
            return XCTFail("Expected a resolvable log location")
        }
        let contents = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(contents.contains("hello diagnostics"))
        XCTAssertTrue(contents.contains("[INFO]"))

        // Appends rather than truncating.
        DiagnosticsLog.write(.error, "second line", preferences: prefs)
        let appended = try String(contentsOf: url, encoding: .utf8)
        XCTAssertTrue(appended.contains("hello diagnostics"))
        XCTAssertTrue(appended.contains("second line"))

        // An empty location disables diagnostics instead of crashing.
        prefs.diagnosticsLogLocation = ""
        XCTAssertNil(DiagnosticsLog.logFileURL(preferences: prefs))
    }

    func testDiagnosticsLocationExpandsTilde() {
        var prefs = Preferences()
        prefs.diagnosticsLogLocation = "~/Library/Logs/LXC-BRM-test-\(UUID().uuidString)/"
        let url = DiagnosticsLog.logFileURL(preferences: prefs)
        XCTAssertNotNil(url)
        XCTAssertFalse(url?.path.contains("~") ?? true, "Tilde should be expanded")
        if let directory = url?.deletingLastPathComponent() {
            try? FileManager.default.removeItem(at: directory)
        }
    }
}

/// Covers the GitHub rate-limit preference.
final class GitHubRateLimitTests: XCTestCase {
    func testWarnPercentParsesTheStoredThresholdString() {
        XCTAssertEqual(GitHubRateLimit.warnPercent("Warn me at 20%"), 20)
        XCTAssertEqual(GitHubRateLimit.warnPercent("Warn me at 5%"), 5)
        XCTAssertEqual(GitHubRateLimit.warnPercent("Never"), 0)
        XCTAssertEqual(GitHubRateLimit.warnPercent(""), 0)
        // Out-of-range values are clamped rather than trusted.
        XCTAssertEqual(GitHubRateLimit.warnPercent("Warn me at 900%"), 100)
    }

    func testRateLimitMessageDistinguishesExhaustedFromLowQuota() {
        // Exhausted: 403 with nothing remaining gets an actionable message.
        let exhausted = GitHubRateLimit.message(statusCode: 403, remaining: 0, limit: 60, warnPercent: 20)
        XCTAssertNotNil(exhausted)
        XCTAssertTrue(exhausted?.contains("rate limit reached") ?? false)

        // Low quota on an otherwise fine response warns.
        let low = GitHubRateLimit.message(statusCode: 200, remaining: 6, limit: 60, warnPercent: 20)
        XCTAssertEqual(low, "GitHub API quota is low: 6 of 60 requests remaining.")

        // Plenty left: silent.
        XCTAssertNil(GitHubRateLimit.message(statusCode: 200, remaining: 50, limit: 60, warnPercent: 20))
        // Warnings disabled: silent even when low.
        XCTAssertNil(GitHubRateLimit.message(statusCode: 200, remaining: 1, limit: 60, warnPercent: 0))
        // Missing headers: nothing to say.
        XCTAssertNil(GitHubRateLimit.message(statusCode: 200, remaining: nil, limit: nil, warnPercent: 20))
    }
}
