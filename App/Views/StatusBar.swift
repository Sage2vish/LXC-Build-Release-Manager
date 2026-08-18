import SwiftUI

struct StatusBar: View {
    let repository: Repository?
    let preferences: Preferences

    @State private var currentBranch: String = "—"

    private var branch: String {
        currentBranch
    }

    var body: some View {
        VStack(spacing: 0) {
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
            .padding(.top, 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial)
        .task(id: repository?.name) {
            if let repository = repository {
                currentBranch = GitBranchReader.currentBranch(for: repository) ?? "—"
            } else {
                currentBranch = "—"
            }
        }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(label))
        .accessibilityValue(Text(value))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.10), in: Capsule())
    }
}

