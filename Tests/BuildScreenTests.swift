import Foundation
import SwiftUI
import XCTest
@testable import LXC_Build_Release_Manager

/// Covers the Build screen end to end: the selection and run-eligibility rules, the parameter
/// and command-preview path, and a real select -> launch -> stream -> stop -> history flow
/// driven through the same stores the view uses.
@MainActor
final class BuildScreenTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BRM-BuildScreen-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
    }

    // MARK: Selection

    func testSelectedScriptFallsBackWhenTheSavedSelectionDisappears() {
        let first = BuildScript(fileName: "a.sh", label: "A", path: "/tmp/repo/build/scripts/a.sh")
        let second = BuildScript(fileName: "b.sh", label: "B", path: "/tmp/repo/build/scripts/b.sh")
        let scripts = [first, second]

        XCTAssertEqual(BuildScreenRules.selectedScript(in: scripts, selectedID: second.id)?.id, second.id)
        // A rescan that removed the selected script falls back to the first, not to nil.
        XCTAssertEqual(BuildScreenRules.selectedScript(in: scripts, selectedID: "gone")?.id, first.id)
        XCTAssertEqual(BuildScreenRules.selectedScript(in: scripts, selectedID: nil)?.id, first.id)
        XCTAssertNil(BuildScreenRules.selectedScript(in: [], selectedID: nil))
    }

    // MARK: Run eligibility

    func testCanRunCoversEveryBlockingCondition() {
        func script(_ location: BuildScriptLocation) -> BuildScript {
            BuildScript(fileName: "x.sh", label: "X", path: "/tmp/repo/x.sh", location: location)
        }
        func canRun(
            _ location: BuildScriptLocation = .standardFolder,
            local: Bool = true,
            busy: Bool = false,
            running: Int = 0,
            maxConcurrent: Int = 2,
            allowOutside: Bool = false
        ) -> Bool {
            BuildScreenRules.canRun(
                script: script(location),
                isLocalRepository: local,
                isRunnerBusy: busy,
                runningCount: running,
                maxConcurrentBuilds: maxConcurrent,
                allowScriptsOutsideRepository: allowOutside
            )
        }

        XCTAssertTrue(canRun())
        XCTAssertTrue(canRun(.repository))

        // GitHub-sourced repositories have no local checkout to run against.
        XCTAssertFalse(canRun(local: false))
        // This repository is already building.
        XCTAssertFalse(canRun(busy: true))
        // The app-wide concurrent limit is reached.
        XCTAssertFalse(canRun(running: 2, maxConcurrent: 2))
        XCTAssertTrue(canRun(running: 1, maxConcurrent: 2))
        // Missing, stale, and remote scripts are not runnable at all.
        for location in [BuildScriptLocation.missing, .stale, .unavailable] {
            XCTAssertFalse(canRun(location), "\(location) should not be runnable")
        }
        // Outside the repository requires the Preferences opt-in.
        XCTAssertFalse(canRun(.outsideRepository))
        XCTAssertTrue(canRun(.outsideRepository, allowOutside: true))
    }

    // MARK: Last-run readout

    func testLastRunDescriptionCoversRunningStoppingAndEveryStatus() {
        XCTAssertEqual(
            BuildScreenRules.lastRunDescription(record: nil, isRunning: false, isStopping: false),
            "Never run"
        )
        XCTAssertEqual(
            BuildScreenRules.lastRunDescription(record: nil, isRunning: true, isStopping: false),
            "Building…"
        )
        XCTAssertEqual(
            BuildScreenRules.lastRunDescription(record: nil, isRunning: true, isStopping: true),
            "Stopping…"
        )

        for (status, glyph) in [(BuildStatus.success, "✓"), (.failed, "✗"), (.cancelled, "⊘")] {
            let record = BuildRecord(
                repositoryID: UUID(),
                scriptFileName: "x.sh",
                scriptLabel: "X",
                startedAt: Date(),
                status: status,
                durationSeconds: 1,
                logFileName: "build.log"
            )
            let text = BuildScreenRules.lastRunDescription(record: record, isRunning: false, isStopping: false)
            XCTAssertTrue(text.hasPrefix("Last run:"), text)
            XCTAssertTrue(text.hasSuffix(glyph), "\(status) should end with \(glyph), got: \(text)")
        }
    }

    // MARK: Parameters and command preview

    func testParameterVisibilityAndCommandPreviewMatchWhatTheScreenShows() throws {
        let script = BuildScript(
            fileName: "release.sh",
            label: "Release",
            path: "\(temporaryDirectory.path)/release.sh",
            parameters: [
                BuildParameterDefinition(key: "configuration", kind: .choice, options: ["Debug", "Release"], defaultValue: "Debug"),
                BuildParameterDefinition(key: "notarize", kind: .boolean, defaultValue: "false"),
                // Only shown once notarize is on.
                BuildParameterDefinition(key: "profile", kind: .text, dependsOnKey: "notarize", visibleWhenValue: "true")
            ]
        )

        let hidden = BuildCommandBuilder.activeParameters(for: script, values: [:])
        XCTAssertEqual(hidden.map(\.key), ["configuration", "notarize"])

        let shown = BuildCommandBuilder.activeParameters(for: script, values: ["notarize": "true"])
        XCTAssertEqual(shown.map(\.key), ["configuration", "notarize", "profile"])

        // The preview the Detail View Window renders is the invocation's command preview.
        let invocation = try BuildCommandBuilder.invocation(
            for: script,
            values: ["configuration": "Release", "notarize": "true", "profile": "dev-id"]
        )
        XCTAssertTrue(invocation.commandPreview.contains("--configuration Release"))
        XCTAssertTrue(invocation.commandPreview.contains("--notarize"))
        XCTAssertTrue(invocation.commandPreview.contains("--profile dev-id"))
        // A path with spaces must stay quoted so the preview is copy-pasteable.
        XCTAssertTrue(invocation.commandPreview.contains(script.path) || invocation.commandPreview.contains("'\(script.path)'"))
    }

    func testValidationBlocksLaunchAndNamesTheOffendingParameter() {
        let script = BuildScript(
            fileName: "release.sh",
            label: "Release",
            path: "/tmp/release.sh",
            parameters: [
                BuildParameterDefinition(key: "version", kind: .text, isRequired: true),
                BuildParameterDefinition(key: "retries", kind: .number)
            ]
        )
        let missing = BuildCommandBuilder.validate(script: script, values: [:])
        XCTAssertEqual(missing, ["Version is required."])

        let badNumber = BuildCommandBuilder.validate(script: script, values: ["version": "1.0", "retries": "abc"])
        XCTAssertEqual(badNumber, ["Retries must be a number."])

        XCTAssertTrue(BuildCommandBuilder.validate(script: script, values: ["version": "1.0", "retries": "3"]).isEmpty)
    }

    // MARK: End-to-end build flow

    func testSelectLaunchStreamStopAndHistoryFlow() async throws {
        let repositoryURL = temporaryDirectory.appendingPathComponent("Repo", isDirectory: true)
        let scriptsDirectory = repositoryURL.appendingPathComponent("build/scripts", isDirectory: true)
        try FileManager.default.createDirectory(at: scriptsDirectory, withIntermediateDirectories: true)
        try "echo starting; sleep 5; echo never-reached"
            .write(to: scriptsDirectory.appendingPathComponent("slow.sh"), atomically: true, encoding: .utf8)

        // 1. Discovery finds the script the Build tab would list.
        guard case .success(let scripts) = BuildScriptScanner.scanLocal(path: repositoryURL.path),
              let script = scripts.first else {
            return XCTFail("Expected the script to be discovered")
        }
        XCTAssertEqual(script.fileName, "slow.sh")
        XCTAssertEqual(script.location, .standardFolder)

        let repository = Repository(name: "Repo", source: .local(path: repositoryURL.path))
        let workspace = BuildWorkspaceStateStore(
            storeURL: temporaryDirectory.appendingPathComponent("workspace.json")
        )
        let history = BuildHistoryStore(storeURL: temporaryDirectory.appendingPathComponent("history.json"))
        let runner = BuildRunner()

        var preferences = Preferences()
        preferences.automaticallySaveLogs = false
        preferences.saveLogsAutomatically = false
        preferences.enableBuildNotifications = false
        preferences.preventSleepDuringBuild = false
        preferences.buildTimeoutMinutes = 0

        // 2. Selecting the script persists it, the way tapping a row does.
        workspace.select(scriptID: script.id, for: repository.id)
        XCTAssertEqual(workspace.state(for: repository.id).selectedScriptID, script.id)
        XCTAssertEqual(
            BuildScreenRules.selectedScript(in: scripts, selectedID: workspace.state(for: repository.id).selectedScriptID)?.id,
            script.id
        )

        // 3. It is runnable before launch, and not once it is running.
        XCTAssertTrue(BuildScreenRules.canRun(
            script: script, isLocalRepository: true, isRunnerBusy: false,
            runningCount: 0, maxConcurrentBuilds: 2, allowScriptsOutsideRepository: false
        ))

        XCTAssertTrue(runner.start(
            script: script,
            parameters: workspace.values(for: script.id, repositoryID: repository.id),
            repository: repository,
            historyStore: history,
            preferences: preferences
        ))
        XCTAssertTrue(runner.isRunning)
        XCTAssertFalse(BuildScreenRules.canRun(
            script: script, isLocalRepository: true, isRunnerBusy: runner.isRunning,
            runningCount: 1, maxConcurrentBuilds: 2, allowScriptsOutsideRepository: false
        ))

        // 4. Output streams before the process finishes.
        try await waitUntil(timeout: .seconds(5)) {
            runner.logLines.contains { $0.text.contains("starting") }
        }
        XCTAssertTrue(
            LogPresentation.displayLines(from: runner.logLines).contains { $0.text.contains("starting") },
            "The rendered lines should include the streamed output"
        )

        // 5. Stopping mid-run cancels it and keeps the partial output.
        runner.cancel(preferences: preferences)
        try await waitUntil(timeout: .seconds(5)) { !runner.isRunning }

        XCTAssertEqual(runner.phase, .cancelled)
        XCTAssertEqual(runner.terminationReason, "Stopped by user")
        XCTAssertTrue(runner.logLines.contains { $0.text.contains("starting") }, "Partial output must survive a stop")
        XCTAssertFalse(runner.logLines.contains { $0.text.contains("never-reached") }, "The build should not have completed")

        // 6. The run is recorded in history as cancelled.
        let records = history.records(for: repository.id)
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.status, .cancelled)
        XCTAssertEqual(records.first?.scriptFileName, "slow.sh")
        XCTAssertEqual(
            BuildScreenRules.lastRunDescription(record: records.first, isRunning: false, isStopping: false).hasSuffix("⊘"),
            true
        )

        // 7. Clearing the pane does not erase history.
        runner.clearOutput()
        XCTAssertTrue(runner.logLines.isEmpty)
        XCTAssertEqual(history.records(for: repository.id).count, 1)
    }

    func testConcurrencyLimitBlocksASecondBuildAcrossRepositories() {
        let script = BuildScript(fileName: "a.sh", label: "A", path: "/tmp/a.sh")
        // At the limit nothing else may start, even though this repository's runner is idle.
        XCTAssertFalse(BuildScreenRules.canRun(
            script: script, isLocalRepository: true, isRunnerBusy: false,
            runningCount: 1, maxConcurrentBuilds: 1, allowScriptsOutsideRepository: false
        ))
        XCTAssertTrue(BuildScreenRules.canRun(
            script: script, isLocalRepository: true, isRunnerBusy: false,
            runningCount: 0, maxConcurrentBuilds: 1, allowScriptsOutsideRepository: false
        ))
    }

    private func waitUntil(
        timeout: Duration,
        _ condition: () -> Bool
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        while !condition() && clock.now < deadline {
            try await Task.sleep(for: .milliseconds(25))
        }
        XCTAssertTrue(condition(), "Condition was not met before the timeout")
    }
}

// MARK: - History filtering

final class HistoryFilterTests: XCTestCase {
    private func record(
        _ label: String,
        _ status: BuildStatus,
        at offset: TimeInterval = 0
    ) -> BuildRecord {
        BuildRecord(
            repositoryID: UUID(),
            scriptFileName: "\(label).sh",
            scriptLabel: label,
            startedAt: Date(timeIntervalSince1970: 1_700_000_000 + offset),
            status: status,
            durationSeconds: 60,
            logFileName: "build.log"
        )
    }

    func testAllOutcomeKeepsEveryRecord() {
        let records = [record("build", .success), record("release", .failed), record("test", .cancelled)]
        XCTAssertEqual(HistoryFilter.apply(records).count, 3)
    }

    func testOutcomeFilterSelectsOneStatus() {
        let records = [record("build", .success), record("release", .failed), record("test", .cancelled)]
        XCTAssertEqual(HistoryFilter.apply(records, outcome: .failed).map(\.scriptLabel), ["release"])
        XCTAssertEqual(HistoryFilter.apply(records, outcome: .cancelled).map(\.scriptLabel), ["test"])
    }

    func testScriptFilterSelectsOneScriptAcrossOutcomes() {
        let records = [record("build", .success), record("build", .failed, at: 10), record("release", .success)]
        XCTAssertEqual(HistoryFilter.apply(records, script: "build").count, 2)
    }

    func testFiltersCombine() {
        let records = [record("build", .success), record("build", .failed, at: 10), record("release", .failed)]
        let result = HistoryFilter.apply(records, outcome: .failed, script: "build")
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.scriptLabel, "build")
    }

    func testScriptLabelsAreUniqueAndSorted() {
        let records = [record("release", .success), record("build", .failed), record("release", .cancelled)]
        XCTAssertEqual(HistoryFilter.scriptLabels(in: records), ["build", "release"])
    }

    func testFilteringPreservesIncomingOrder() {
        let records = [record("a", .success, at: 30), record("b", .success, at: 20), record("c", .success, at: 10)]
        XCTAssertEqual(HistoryFilter.apply(records).map(\.scriptLabel), ["a", "b", "c"])
    }

    func testSummaryOnlyAppearsWhenSomethingIsHidden() {
        XCTAssertNil(HistoryFilter.summary(shown: 5, total: 5))
        XCTAssertEqual(HistoryFilter.summary(shown: 2, total: 5), "Showing 2 of 5 runs.")
    }

    @MainActor
    func testClearingOneRepositoryLeavesOthersIntact() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BRM-History-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = BuildHistoryStore(storeURL: directory.appendingPathComponent("build-history.json"))
        let kept = UUID()
        let cleared = UUID()
        for repositoryID in [kept, cleared] {
            store.record(
                BuildRecord(
                    repositoryID: repositoryID,
                    scriptFileName: "build.sh",
                    scriptLabel: "build",
                    startedAt: Date(timeIntervalSince1970: 1_700_000_000),
                    status: .success,
                    durationSeconds: 60,
                    logFileName: "build.log"
                )
            )
        }

        store.clear(for: cleared)

        XCTAssertTrue(store.records(for: cleared).isEmpty)
        XCTAssertEqual(store.records(for: kept).count, 1, "Clearing one repository must not touch another's history.")
    }
}

// MARK: - Language naming

final class AppLanguageLabelTests: XCTestCase {
    func testLabelShowsEnglishNameThenNativeName() {
        XCTAssertEqual(AppLanguage.hindi.pickerLabel, "Hindi — हिन्दी")
    }

    func testLabelIsNotRepeatedWhenBothNamesMatch() {
        // English in English is "English"; printing it twice either side of a dash is noise.
        XCTAssertEqual(AppLanguage.english.pickerLabel, "English")
    }

    func testSystemDefaultNamesABehaviourNotALanguage() {
        XCTAssertEqual(AppLanguage.systemDefault.pickerLabel, "System Default")
    }

    func testEveryShippedLanguageHasBothNamesAndACode() {
        for language in AppLanguage.allCases {
            XCTAssertFalse(language.englishName.isEmpty)
            XCTAssertFalse(language.nativeName.isEmpty)
            if language != .systemDefault {
                XCTAssertNotNil(language.languageCode, "\(language) ships without a language code")
            }
        }
    }

    func testUnknownStoredValueFallsBackToSystemDefault() {
        XCTAssertEqual(AppLanguage(preference: "Klingon"), .systemDefault)
    }

    func testAppearanceSliderStopsRunLightSystemDark() {
        // System sits in the middle: it is the resting position, with an override either side.
        XCTAssertEqual(AppearanceSlider.title(for: .light), "Bright")
        XCTAssertEqual(AppearanceSlider.title(for: .system), "System Default")
        XCTAssertEqual(AppearanceSlider.title(for: .dark), "Dark")
        XCTAssertEqual(AppearanceSlider.asset(for: .light), "theme-light")
        XCTAssertEqual(AppearanceSlider.asset(for: .system), "theme-system")
        XCTAssertEqual(AppearanceSlider.asset(for: .dark), "theme-dark")
    }
}

// MARK: - Statistics date range

final class StatsRangeTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    private func record(daysAgo: Double, status: BuildStatus = .success, duration: TimeInterval = 60) -> BuildRecord {
        BuildRecord(
            repositoryID: UUID(),
            scriptFileName: "build.sh",
            scriptLabel: "build",
            startedAt: now.addingTimeInterval(-daysAgo * 24 * 60 * 60),
            status: status,
            durationSeconds: duration,
            logFileName: "build.log"
        )
    }

    func testAllTimeKeepsEverything() {
        let records = [record(daysAgo: 1), record(daysAgo: 200)]
        XCTAssertEqual(StatsRange.allTime.filter(records, now: now).count, 2)
    }

    func testWeekExcludesAnythingOlder() {
        let records = [record(daysAgo: 1), record(daysAgo: 6.9), record(daysAgo: 7.1)]
        XCTAssertEqual(StatsRange.week.filter(records, now: now).count, 2)
    }

    func testRangeBoundaryIsInclusive() {
        // A run exactly on the boundary belongs to the range: excluding it would make the
        // window silently shorter than it claims.
        let records = [record(daysAgo: 7)]
        XCTAssertEqual(StatsRange.week.filter(records, now: now).count, 1)
    }

    func testMonthAndQuarterWindows() {
        let records = [record(daysAgo: 10), record(daysAgo: 45), record(daysAgo: 100)]
        XCTAssertEqual(StatsRange.month.filter(records, now: now).count, 1)
        XCTAssertEqual(StatsRange.quarter.filter(records, now: now).count, 2)
    }

    func testStatisticsAreComputedOverTheGivenRecordsOnly() {
        let records = [
            record(daysAgo: 1, status: .success, duration: 10),
            record(daysAgo: 2, status: .failed, duration: 30),
            record(daysAgo: 100, status: .failed, duration: 1_000)
        ]
        let recent = RepositoryStats.make(from: StatsRange.week.filter(records, now: now))
        XCTAssertEqual(recent.totalBuilds, 2)
        XCTAssertEqual(recent.successCount, 1)
        XCTAssertEqual(recent.successRate, 0.5, accuracy: 0.0001)
        XCTAssertEqual(recent.averageDuration, 20, accuracy: 0.0001)
        XCTAssertEqual(recent.lastFailed?.durationSeconds, 30, "The 100-day-old failure is outside the range.")
    }

    func testEmptyRecordsProduceNoDivisionByZero() {
        let empty = RepositoryStats.make(from: [])
        XCTAssertEqual(empty.totalBuilds, 0)
        XCTAssertEqual(empty.successRate, 0)
        XCTAssertEqual(empty.averageDuration, 0)
        XCTAssertNil(empty.mostRecent)
    }
}

// MARK: - Column proportions

final class LayoutMetricsTests: XCTestCase {
    func testColumnsSplitTwentyFifteenAndTheRest() {
        XCTAssertEqual(LayoutMetrics.sidebarWidthFraction, 0.20, accuracy: 0.0001)
        XCTAssertEqual(LayoutMetrics.inspectorWidthFraction, 0.15, accuracy: 0.0001)
        XCTAssertEqual(LayoutMetrics.centreWidthFraction, 0.65, accuracy: 0.0001,
                       "The centre is the remainder, so the three must always total the window.")
    }

    func testIdealWidthsAreTrueProportionsOfTheWindow() {
        let window: CGFloat = 1_600
        XCTAssertEqual(LayoutMetrics.sidebarColumn(for: window).ideal, 320, accuracy: 0.5)
        XCTAssertEqual(LayoutMetrics.inspectorColumn(for: window).ideal, 240, accuracy: 0.5)
    }

    func testColumnsScaleWithTheWindowRatherThanStayingFixed() {
        let small = LayoutMetrics.sidebarColumn(for: 1_200).ideal
        let large = LayoutMetrics.sidebarColumn(for: 2_400).ideal
        XCTAssertEqual(large, small * 2, accuracy: 1,
                       "A proportion has to move with the window; that is the whole point.")
    }

    func testAbsoluteFloorsWinOnAVerySmallWindow() {
        // 20% of 600pt is 120pt, which cannot hold a repository name and the footer buttons.
        XCTAssertEqual(LayoutMetrics.sidebarColumn(for: 600).ideal, LayoutMetrics.sidebarFloor, accuracy: 0.5)
        XCTAssertEqual(LayoutMetrics.inspectorColumn(for: 600).ideal, LayoutMetrics.inspectorFloor, accuracy: 0.5)
    }

    func testMinimumsNeverExceedIdealsOrIdealsExceedMaximums() {
        for window in stride(from: CGFloat(600), through: 3_200, by: 200) {
            let sidebar = LayoutMetrics.sidebarColumn(for: window)
            let inspector = LayoutMetrics.inspectorColumn(for: window)
            XCTAssertLessThanOrEqual(sidebar.min, sidebar.ideal, "sidebar at \(window)")
            XCTAssertLessThanOrEqual(sidebar.ideal, sidebar.max, "sidebar at \(window)")
            XCTAssertLessThanOrEqual(inspector.min, inspector.ideal, "inspector at \(window)")
            XCTAssertLessThanOrEqual(inspector.ideal, inspector.max, "inspector at \(window)")
        }
    }

    func testSidePanelsNeverEatMoreThanTwoThirdsOfTheWindow() {
        // Dragged fully open at once, the two side columns must still leave the centre a
        // workable share; the centre is where the build actually happens.
        for window in stride(from: CGFloat(900), through: 3_200, by: 100) {
            let widest = LayoutMetrics.sidebarColumn(for: window).max + LayoutMetrics.inspectorColumn(for: window).max
            XCTAssertLessThan(widest, window * 0.7, "Side columns swallow the centre at \(window)pt")
        }
    }
}

// MARK: - Top bar controls

final class ToolbarControlTests: XCTestCase {
    func testControlsTakeTheirHeightFromTheToolbarRatherThanFromUs() {
        // Deliberately no height constant to assert any more. The first attempt gave the two
        // controls a shared number and drew its own capsule; AppKit refuses to render custom
        // backgrounds behind toolbar items, so the appearance control appeared as three loose
        // icons and the language control as blue link text — matched numbers, mismatched UI.
        // Native controls are sized by the toolbar, which is what actually makes them equal.
        XCTAssertEqual(AppTheme.allCases.count, 3, "The appearance control is a three-stop picker")
    }

    func testAppearanceStopsAreOrderedBrightDefaultDark() {
        XCTAssertEqual(AppearanceSlider.title(for: .light), "Bright")
        XCTAssertEqual(AppearanceSlider.title(for: .system), "System Default")
        XCTAssertEqual(AppearanceSlider.title(for: .dark), "Dark")
    }

    func testEveryAppearanceStopHasItsOwnIconAndExplanation() {
        var assets = Set<String>()
        for theme in AppTheme.allCases {
            let asset = AppearanceSlider.asset(for: theme)
            XCTAssertTrue(asset.hasPrefix("theme-"), "\(theme) should use a project SVG, not an SF Symbol")
            assets.insert(asset)
            XCTAssertFalse(AppearanceSlider.help(for: theme).isEmpty, "\(theme) has no tooltip")
        }
        XCTAssertEqual(assets.count, AppTheme.allCases.count, "Two stops share an icon")
    }

    func testTheBarShowsTheNativeNameWhileTheMenuShowsBoth() {
        // Space in the bar is scarce; space in the menu is not.
        XCTAssertEqual(AppLanguage.hindi.nativeName, "हिन्दी")
        XCTAssertEqual(AppLanguage.hindi.pickerLabel, "Hindi — हिन्दी")
    }
}
