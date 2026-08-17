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
