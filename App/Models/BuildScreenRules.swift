import Foundation
import SwiftUI

/// The decision rules behind the Build screen: which script is selected, whether it can run,
/// and how its last run reads.
///
/// These were private helpers on `RepositoryDetailView`, so none of them could be tested
/// without standing up a view. They are pure functions here — the view supplies the state.
enum BuildScreenRules {
    /// Falls back to the first script when the saved selection no longer exists, which happens
    /// after a rescan removes or renames a script.
    static func selectedScript(in scripts: [BuildScript], selectedID: String?) -> BuildScript? {
        if let selectedID, let match = scripts.first(where: { $0.id == selectedID }) {
            return match
        }
        return scripts.first
    }

    /// A script is runnable only from a local checkout, when its file is actually present, when
    /// this repository is idle, and when the app is under the concurrent-build limit.
    /// Scripts outside the repository need the Preferences opt-in.
    static func canRun(
        script: BuildScript,
        isLocalRepository: Bool,
        isRunnerBusy: Bool,
        runningCount: Int,
        maxConcurrentBuilds: Int,
        allowScriptsOutsideRepository: Bool
    ) -> Bool {
        guard isLocalRepository,
              script.location.isRunnable,
              !isRunnerBusy,
              runningCount < maxConcurrentBuilds else {
            return false
        }
        return script.location != .outsideRepository || allowScriptsOutsideRepository
    }

    static func lastRunDescription(
        record: BuildRecord?,
        isRunning: Bool,
        isStopping: Bool
    ) -> String {
        if isRunning { return isStopping ? "Stopping…" : "Building…" }
        guard let record else { return "Never run" }
        return "Last run: \(record.startedAt.relativeDescription) \(BuildPresentation.glyph(for: record.status))"
    }

    static func lastRunColor(record: BuildRecord?, isRunning: Bool) -> Color {
        if isRunning { return .blue }
        guard let record else { return .secondary }
        return BuildPresentation.color(for: record.status)
    }
}
