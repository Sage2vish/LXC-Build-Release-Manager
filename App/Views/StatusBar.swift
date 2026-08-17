import SwiftUI

struct StatusBar: View {
    let repository: Repository?
    let preferences: Preferences

    private var branch: String {
        guard let repository, let branch = GitBranchReader.currentBranch(for: repository) else { return "—" }
        return branch
    }

    var body: some View {
        HStack(spacing: 12) {
            statusItem("Repository", repository?.name ?? "—", icon: "folder.fill", tint: .blue)
            statusItem("Branch", branch, icon: "arrow.triangle.branch", tint: .orange)
            statusItem("Platform", "macOS", icon: "desktopcomputer", tint: .indigo)
            statusItem(
                "Auto-detect",
                preferences.autoDetectRepositoriesOnStartup ? "Enabled" : "Disabled",
                icon: preferences.autoDetectRepositoriesOnStartup ? "checkmark.circle.fill" : "pause.circle.fill",
                tint: preferences.autoDetectRepositoriesOnStartup ? .green : .secondary
            )
            Spacer()
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private func statusItem(_ label: String, _ value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text("\(label):")
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(tint)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.10), in: Capsule())
    }
}
