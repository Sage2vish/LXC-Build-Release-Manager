import SwiftUI

struct StatusBar: View {
    let repository: Repository?
    let preferences: Preferences

    @Environment(\.scenePhase) private var scenePhase
    @State private var currentBranch: String = StatusBar.unknownValue

    /// Shown wherever a field has nothing true to say. One constant so the strip is consistent
    /// and a test can assert against it.
    static let unknownValue = "—"

    var body: some View {
        HStack(spacing: 12) {
            statusItem("Repository", repository?.name ?? Self.unknownValue, icon: "folder.fill", tint: .blue)
            branchItem
            statusItem("Platform", "macOS", icon: "desktopcomputer", tint: .indigo)
            statusItem(
                "Auto-detect",
                preferences.autoDetectRepositoriesOnStartup ? "Enabled" : "Disabled",
                icon: preferences.autoDetectRepositoriesOnStartup ? "checkmark.circle.fill" : "pause.circle.fill",
                tint: preferences.autoDetectRepositoriesOnStartup ? .green : .secondary
            )
            Spacer(minLength: 0)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        // One height, named once. The sidebar and the centre column reserve the same number at
        // their bottom, so the strip lies over glass rather than pushing anything around.
        .frame(height: LayoutMetrics.statusBarHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlassSurface(.ultraThin, hairline: .top, reduceTransparency: preferences.reduceTransparency))
        .task(id: repository?.id) { refreshBranch() }
        // The branch is a file on disk that other tools change while the app is open. Re-reading
        // when the window comes back to the front is enough to keep the chip honest without
        // polling `.git/HEAD` on a timer.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refreshBranch() }
        }
    }

    /// The branch chip, with an explanation attached wherever the value is not a branch name.
    ///
    /// A bare "—" invites the reading that the app failed. Saying *why* there is no branch is the
    /// difference between a gap and a bug.
    private var branchItem: some View {
        statusItem("Branch", currentBranch, icon: "arrow.triangle.branch", tint: .orange)
            .help(branchExplanation)
            .onTapGesture { refreshBranch() }
    }

    private var branchExplanation: String {
        guard let repository else { return "No repository selected." }
        if !repository.source.isLocal {
            return "A GitHub-sourced repository has no local checkout, so there is no .git/HEAD to read. Add the same repository as a local folder to see its branch."
        }
        if currentBranch == Self.unknownValue {
            return "No .git/HEAD found in this folder — it is not a git working copy, or the folder has moved."
        }
        if currentBranch.hasPrefix("detached") {
            return "HEAD is detached: the checkout is at a specific commit rather than on a branch."
        }
        return "Read from .git/HEAD. Click to re-read it."
    }

    private func refreshBranch() {
        guard let repository else {
            currentBranch = Self.unknownValue
            return
        }
        currentBranch = GitBranchReader.currentBranch(for: repository) ?? Self.unknownValue
    }

    private func statusItem(_ label: LocalizedStringKey, _ value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            // Parenthesised deliberately. Without them `.foregroundStyle` binds to the colon
            // alone, leaving the label at full strength where it was meant to recede behind the
            // tinted value beside it.
            (Text(label) + Text(verbatim: ":"))
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(tint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(value))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.10), in: Capsule())
    }
}
