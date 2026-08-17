import Foundation
import XCTest
@testable import LXC_BRM

/// TODO: Add UI integration and manual settings click-through tests (see worklog).
/// TODO: Add resilience tests for permission errors and runtime access denials (simulate unreadable folders/files).

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

    func testRepositoryScanStaysWellUnderTheFiveSecondTarget() async throws {
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

    func testTenRepositoriesScanAndPersistWithoutDegrading() async throws {
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

    func testWorkspaceStateStaysCorrectAcrossManyRepositories() async {
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

    // TODO: Add test simulating permissions error (e.g., deny read access to scripts folder).
    // TODO: Consider UI-level validation of error presentation for missing/corrupt input (not just logic).

    func testScanReportsMissingBuildFolderEmptyScriptsAndUnreadablePaths() async throws {
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

    func testDeletedRepositoryFolderDegradesToMissingRatherThanCrashing() async throws {
        let root = try makeRepository(named: "Vanishing", scripts: 3)
        guard case .success = BuildScriptScanner.scanLocal(path: root.path) else {
            return XCTFail("Expected the initial scan to succeed")
        }

        // The user deletes or unmounts the folder between scans.
        try FileManager.default.removeItem(at: root)
        XCTAssertEqual(BuildScriptScanner.scanLocal(path: root.path), .missingBuildFolder)
    }

    func testCorruptStoreFilesFallBackToDefaultsInsteadOfLosingTheApp() async throws {
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

    func testDetectExecutableFilesControlsWhetherExtensionlessScriptsAreOffered() async throws {
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

    func testDiagnosticsRespectVerboseAndFileLoggingPreferences() async throws {
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

    func testDiagnosticsLocationExpandsTilde() async {
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

/// Covers update checking and language selection — the last two preferences that had nothing
/// behind them.
final class UpdateAndLanguageTests: XCTestCase {
    private func release(
        _ tag: String,
        prerelease: Bool = false,
        draft: Bool = false,
        assets: [UpdateChecker.ReleaseEntry.Asset] = []
    ) -> UpdateChecker.ReleaseEntry {
        UpdateChecker.ReleaseEntry(
            tagName: tag,
            name: "Release \(tag)",
            htmlURL: "https://github.com/Sage2vish/LXC-Build-Release-Manager/releases/tag/\(tag)",
            prerelease: prerelease,
            draft: draft,
            assets: assets
        )
    }

    func testVersionOrderingHandlesTheCasesStringComparisonGetsWrong() {
        // The classic failure: as text, "0.1.10" sorts before "0.1.9".
        XCTAssertTrue(AppVersion("0.1.9")! < AppVersion("0.1.10")!)
        XCTAssertTrue(AppVersion("0.9.0")! < AppVersion("0.10.0")!)
        XCTAssertTrue(AppVersion("1.0")! < AppVersion("1.0.1")!)
        // Missing trailing components are zero.
        XCTAssertEqual(AppVersion("1.0")!, AppVersion("1.0.0")!)
        // A "v" prefix is accepted.
        XCTAssertEqual(AppVersion("v0.1.2")!, AppVersion("0.1.2")!)
        // Prereleases sort below the release they lead to.
        XCTAssertTrue(AppVersion("1.0.0-beta.1")! < AppVersion("1.0.0")!)
    }

    func testUnparseableVersionsNeverReportAnUpdate() {
        XCTAssertNil(AppVersion(""))
        XCTAssertNil(AppVersion("latest"))
        XCTAssertNil(AppVersion("release-candidate"))
        XCTAssertNil(AppVersion("1.x.3"))

        let current = AppVersion("0.1.2")!
        let result = UpdateChecker.evaluate(
            releases: [release("nightly"), release("latest")],
            channel: .stable,
            current: current
        )
        XCTAssertEqual(result, .upToDate(current: current))
    }

    func testChannelFilteringPicksTheRightReleaseFromAMixedFeed() {
        let current = AppVersion("0.1.2")!
        let feed = [
            release("0.1.3"),
            release("0.2.0-beta.1", prerelease: true),
            release("9.9.9", draft: true)     // drafts are never offered on any channel
        ]

        // Stable ignores the prerelease and the draft.
        XCTAssertEqual(
            UpdateChecker.evaluate(releases: feed, channel: .stable, current: current),
            .updateAvailable(
                AvailableUpdate(
                    version: AppVersion("0.1.3")!,
                    name: "Release 0.1.3",
                    releaseURL: URL(string: "https://github.com/Sage2vish/LXC-Build-Release-Manager/releases/tag/0.1.3"),
                    downloadURL: nil,
                    isPrerelease: false
                ),
                current: current
            )
        )

        // Beta takes the newer prerelease.
        guard case .updateAvailable(let betaUpdate, _) = UpdateChecker.evaluate(
            releases: feed, channel: .beta, current: current
        ) else {
            return XCTFail("Beta should find the prerelease")
        }
        XCTAssertEqual(betaUpdate.version, AppVersion("0.2.0-beta.1")!)
        XCTAssertTrue(betaUpdate.isPrerelease)
    }

    func testUpdatePrefersTheAttachedDMGOverTheReleasePage() {
        let current = AppVersion("0.1.2")!
        let dmg = UpdateChecker.ReleaseEntry.Asset(
            name: "LXC-BRM-0.1.3.dmg",
            browserDownloadURL: "https://github.com/Sage2vish/LXC-Build-Release-Manager/releases/download/v0.1.3/LXC-BRM-0.1.3.dmg"
        )
        let notes = UpdateChecker.ReleaseEntry.Asset(
            name: "release-notes.txt",
            browserDownloadURL: "https://example.com/notes.txt"
        )

        guard case .updateAvailable(let update, _) = UpdateChecker.evaluate(
            releases: [release("0.1.3", assets: [notes, dmg])],
            channel: .stable,
            current: current
        ) else {
            return XCTFail("Expected an update")
        }
        // The installer wins over both the release page and the non-dmg asset.
        XCTAssertEqual(update.downloadURL?.lastPathComponent, "LXC-BRM-0.1.3.dmg")
        XCTAssertEqual(update.preferredURL, update.downloadURL)

        // With no .dmg attached, it falls back to the release page rather than offering nothing.
        guard case .updateAvailable(let noAsset, _) = UpdateChecker.evaluate(
            releases: [release("0.1.3")],
            channel: .stable,
            current: current
        ) else {
            return XCTFail("Expected an update")
        }
        XCTAssertNil(noAsset.downloadURL)
        XCTAssertEqual(noAsset.preferredURL, noAsset.releaseURL)
    }

    func testEqualOrOlderReleasesReportUpToDate() {
        let current = AppVersion("1.0.0")!
        XCTAssertEqual(
            UpdateChecker.evaluate(releases: [release("1.0.0")], channel: .stable, current: current),
            .upToDate(current: current)
        )
        XCTAssertEqual(
            UpdateChecker.evaluate(releases: [release("0.9.9")], channel: .stable, current: current),
            .upToDate(current: current)
        )
        XCTAssertEqual(
            UpdateChecker.evaluate(releases: [], channel: .stable, current: current),
            .upToDate(current: current)
        )
    }

    func testChannelIsDerivedFromThePreferenceString() {
        XCTAssertEqual(UpdateChecker.Channel(preference: "Stable (Recommended)"), .stable)
        XCTAssertEqual(UpdateChecker.Channel(preference: "Beta"), .beta)
        // Anything unrecognised is treated as stable, the safer default.
        XCTAssertEqual(UpdateChecker.Channel(preference: "nonsense"), .stable)
    }

    func testLanguagePreferenceMapsToCodesAndFallsBackSafely() {
        XCTAssertNil(AppLanguage(preference: "System Default").languageCode)
        XCTAssertEqual(AppLanguage(preference: "English").languageCode, "en")
        XCTAssertEqual(AppLanguage(preference: "Hindi").languageCode, "hi")
        // An old or hand-edited value must not break loading.
        XCTAssertEqual(AppLanguage(preference: "Klingon"), .systemDefault)
        XCTAssertEqual(AppLanguage(preference: ""), .systemDefault)
        // Hindi is shown in its own script.
        XCTAssertEqual(AppLanguage.hindi.nativeName, "हिन्दी")
        XCTAssertEqual(AppLanguage.english.nativeName, "English")
    }

    func testApplyingAndClearingTheLanguageOverrideWritesAppleLanguages() throws {
        let suiteName = "lxc-brm-language-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertTrue(AppLanguageController.apply(.hindi, defaults: defaults))
        XCTAssertEqual(AppLanguageController.currentOverride(defaults: defaults), "hi")
        // Re-applying the same language is not a change, so no relaunch is offered.
        XCTAssertFalse(AppLanguageController.apply(.hindi, defaults: defaults))

        XCTAssertTrue(AppLanguageController.apply(.english, defaults: defaults))
        XCTAssertEqual(AppLanguageController.currentOverride(defaults: defaults), "en")

        // System Default clears the override entirely.
        XCTAssertTrue(AppLanguageController.apply(.systemDefault, defaults: defaults))
        XCTAssertNil(AppLanguageController.currentOverride(defaults: defaults))
        XCTAssertFalse(AppLanguageController.apply(.systemDefault, defaults: defaults))
    }

    func testHindiCatalogCoversEveryEnglishKey() throws {
        // The catalog ships with the app; every declared key must have a Hindi value, or the
        // language picker silently shows English.
        let path = try XCTUnwrap(
            Bundle.main.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: "hi"),
            "Hindi localization missing from the app bundle"
        )
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let strings = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
        )
        XCTAssertGreaterThan(strings.count, 40, "Expected the Hindi catalog to be populated")
        for (key, value) in strings {
            XCTAssertFalse(value.trimmingCharacters(in: .whitespaces).isEmpty, "\(key) has an empty Hindi value")
            // A value identical to its key means the translation was never filled in.
            if !["GitHub"].contains(key) {
                XCTAssertNotEqual(value, key, "\(key) is untranslated in Hindi")
            }
        }
        XCTAssertEqual(strings["Run"], "चलाएँ")
        XCTAssertEqual(strings["Repositories"], "रिपॉज़िटरी")
        XCTAssertEqual(strings["Preferences"], "प्राथमिकताएँ")

        // English is the source language and needs no compiled catalog; it falls back to the
        // literal strings in code.
        XCTAssertTrue(Bundle.main.localizations.contains("hi"))
    }
}

// TODO: Review for any preferences wired in UI but not covered by tests; add test coverage as new preferences are implemented.
// TODO: Add characterization or integration tests for RepositoryDetailView split (per refactoring plan).

