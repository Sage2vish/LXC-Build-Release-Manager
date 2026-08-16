import SwiftUI

struct BRMArea: Identifiable {
    let id = UUID()
    let name: String
    let purpose: String
    let todoPath: String
    let outputPath: String?
    let extraPath: String?
}

private let brmAreas: [BRMArea] = [
    .init(name: "LXC-BRM-shared", purpose: "Shared utilities and conventions.", todoPath: "to-do-26-08-16.md", outputPath: nil, extraPath: nil),
    .init(name: "LXC-BRM-frameworks", purpose: "Framework-specific assets only.", todoPath: "to-do-26-08-16.md", outputPath: nil, extraPath: nil),
    .init(name: "LXC-BRM-build-release", purpose: "Build and release orchestration.", todoPath: "to-do-26-08-16.md", outputPath: "version/", extraPath: "scripts/ · logs/ · projects.json"),
    .init(name: "LXC-BRM-worklog", purpose: "Daily worklog and execution notes.", todoPath: "to-do-26-08-16.md", outputPath: nil, extraPath: nil),
    .init(name: "LXC-BRM-context", purpose: "Context, decisions, and references.", todoPath: "to-do-26-08-16.md", outputPath: nil, extraPath: nil)
]

struct ContentView: View {
    @State private var selection = "LXC-BRM-build-release"

    var selectedArea: BRMArea {
        brmAreas.first { $0.name == selection } ?? brmAreas[0]
    }

    var body: some View {
        NavigationSplitView {
            List(brmAreas, selection: $selection) { area in
                VStack(alignment: .leading, spacing: 4) {
                    Text(area.name)
                        .font(.headline)
                    Text(area.purpose)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(area.todoPath)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .tag(area.name)
            }
            .navigationTitle("BRM Areas")
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    folderCard
                    todoCard
                    worklogCard
                }
                .padding(24)
            }
            .background(
                LinearGradient(colors: [Color.black.opacity(0.92), Color.gray.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LXC-BRM")
                .font(.system(size: 34, weight: .semibold))
            Text("Native macOS workspace for shared, frameworks, build-release, worklog, and context folders.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var folderCard: some View {
        GroupBox("Selected Area") {
            VStack(alignment: .leading, spacing: 10) {
                Text(selectedArea.name)
                    .font(.title2.weight(.semibold))
                Text(selectedArea.purpose)
                    .foregroundStyle(.secondary)
                Text("Todo file: \(selectedArea.todoPath)")
                    .font(.callout.monospaced())
                if let outputPath = selectedArea.outputPath {
                    Text("Release output: \(outputPath) (final .dmg lands here)")
                        .font(.callout.monospaced())
                }
                if let extraPath = selectedArea.extraPath {
                    Text("Extra paths: \(extraPath)")
                        .font(.callout.monospaced())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    private var todoCard: some View {
        GroupBox("Todo Convention") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Each area keeps a dated note in `to-do-YY-MM-DD.md` format.")
                Text("Starter note: `to-do-26-08-16.md`.")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    private var worklogCard: some View {
        GroupBox("Workspace Notes") {
            VStack(alignment: .leading, spacing: 8) {
                Text("• LXC-BRM-shared for reusable helpers")
                Text("• LXC-BRM-frameworks for framework-specific files")
                Text("• LXC-BRM-build-release for packaging and release steps")
                Text("• LXC-BRM-build-release/version for the final .dmg")
                Text("• LXC-BRM-build-release/scripts, logs, and projects.json")
                Text("• LXC-BRM-worklog for daily tracking")
                Text("• LXC-BRM-context for decisions and references")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}
