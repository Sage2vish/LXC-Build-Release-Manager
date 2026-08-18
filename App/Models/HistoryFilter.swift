import Foundation

/// Filtering rules for the History tab.
///
/// Pure and separate from the view so the behaviour can be tested without a window: a filter that
/// silently hides a run is worse than no filter, and the only way to know it does not is to assert
/// it.
enum HistoryFilter {
    /// Which outcomes to show. `running` is deliberately absent: a run still in progress has no
    /// place in a record of what happened, and the Build tab already shows it live.
    enum Outcome: String, CaseIterable, Identifiable {
        case all = "All"
        case succeeded = "Succeeded"
        case failed = "Failed"
        case cancelled = "Cancelled"

        var id: String { rawValue }

        func matches(_ status: BuildStatus) -> Bool {
            switch self {
            case .all: return true
            case .succeeded: return status == .success
            case .failed: return status == .failed
            case .cancelled: return status == .cancelled
            }
        }
    }

    /// The sentinel for "every script", kept as a constant so the view and the tests cannot
    /// disagree about what an unfiltered script selection looks like.
    static let allScripts = "All scripts"

    /// Every script label present in these records, ordered for a menu.
    ///
    /// Derived from the records themselves rather than from the scripts currently on disk: a run
    /// of a script that has since been deleted is still part of the history, and hiding it would
    /// make the list quietly wrong.
    static func scriptLabels(in records: [BuildRecord]) -> [String] {
        var seen = Set<String>()
        var labels: [String] = []
        for record in records where seen.insert(record.scriptLabel).inserted {
            labels.append(record.scriptLabel)
        }
        return labels.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    /// Applies both filters, preserving the order the records arrived in.
    static func apply(
        _ records: [BuildRecord],
        outcome: Outcome = .all,
        script: String = allScripts
    ) -> [BuildRecord] {
        records.filter { record in
            outcome.matches(record.status)
                && (script == allScripts || record.scriptLabel == script)
        }
    }

    /// A short description of what the filters currently hide, or `nil` when nothing is hidden.
    ///
    /// Shown next to the list so a filtered view can never be mistaken for an empty history —
    /// the difference between "nothing ran" and "nothing matches" matters.
    static func summary(shown: Int, total: Int) -> String? {
        guard shown < total else { return nil }
        return "Showing \(shown) of \(total) runs."
    }
}
