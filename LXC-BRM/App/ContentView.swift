import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var store = RepositoryStore()
    @State private var isAddingRepository = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let repository = store.selectedRepository {
                RepositoryDetailView(repository: repository)
            } else {
                ContentUnavailableView(
                    "Select a Repository",
                    systemImage: "shippingbox",
                    description: Text("Choose a repository from the sidebar, or add one to begin.")
                )
                .background(.background)
            }
        }
        .sheet(isPresented: $isAddingRepository) {
            AddRepositorySheet(store: store, isPresented: $isAddingRepository)
        }
    }

    private var sidebar: some View {
        List(
            selection: Binding(
                get: { store.selectedRepositoryID },
                set: { newValue in
                    if let id = newValue, let repository = store.repositories.first(where: { $0.id == id }) {
                        store.select(repository)
                    }
                }
            )
        ) {
            ForEach(store.repositories) { repository in
                RepositoryRow(repository: repository, store: store)
                    .tag(repository.id)
            }
        }
        .navigationTitle("Build Manager")
        .toolbar {
            ToolbarItem {
                Button {
                    isAddingRepository = true
                } label: {
                    Label("Add Repository", systemImage: "plus")
                }
            }
        }
        .overlay {
            if store.repositories.isEmpty {
                ContentUnavailableView(
                    "No Repositories",
                    systemImage: "folder.badge.plus",
                    description: Text("Add a local folder or GitHub URL to get started.")
                )
            }
        }
    }
}

private struct RepositoryRow: View {
    let repository: Repository
    @ObservedObject var store: RepositoryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: repository.source.isLocal ? "folder" : "chevron.left.forwardslash.chevron.right")
                    .foregroundStyle(.secondary)
                Text(repository.name)
                    .font(.headline)
                if repository.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Text(repository.source.displayPath)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button(repository.isPinned ? "Unpin" : "Pin") {
                store.togglePin(repository)
            }
            Button("Remove", role: .destructive) {
                store.remove(repository)
            }
        }
    }
}

private struct AddRepositorySheet: View {
    @ObservedObject var store: RepositoryStore
    @Binding var isPresented: Bool
    @State private var githubURL: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Repository")
                .font(.title2.weight(.semibold))
            Text("Point to a local folder or paste a GitHub repository URL.")
                .foregroundStyle(.secondary)

            Button {
                pickLocalFolder()
            } label: {
                Label("Choose Local Folder…", systemImage: "folder")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("GitHub URL")
                    .font(.callout.weight(.medium))
                TextField("https://github.com/user/repo", text: $githubURL)
                    .textFieldStyle(.roundedBorder)
                Button("Add GitHub Repository") {
                    let trimmed = githubURL.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.addGitHubRepository(urlString: trimmed)
                    isPresented = false
                }
                .disabled(githubURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
            }
        }
        .padding(24)
        .frame(width: 420)
    }

    private func pickLocalFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Repository"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.addLocalRepository(path: url.path)
        isPresented = false
    }
}

private struct RepositoryDetailView: View {
    let repository: Repository
    @State private var selectedTab: DetailTab = .build
    @State private var scanResult: BuildScanResult?
    @State private var isScanning = false

    enum DetailTab: String, CaseIterable, Identifiable {
        case build = "Build"
        case logs = "Logs"
        case history = "History"
        case overview = "Overview"
        case settings = "Settings"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Picker("", selection: $selectedTab) {
                ForEach(DetailTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding([.horizontal, .bottom])

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .build:
                        buildTab
                    case .logs:
                        comingSoon("Phase 3 — log storage, search, filters, and export.")
                    case .history:
                        comingSoon("Phase 4 — per-repo build history and stats.")
                    case .overview:
                        comingSoon("Phase 4 — repo overview and quick stats.")
                    case .settings:
                        comingSoon("Phase 5 — multi-repo pin and favorite management.")
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(.background)
        .task(id: repository.id) { await scan() }
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await scan() }
                } label: {
                    Label("Rescan", systemImage: "arrow.clockwise")
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(repository.name)
                    .font(.system(size: 24, weight: .semibold))
                statusBadge
            }
            Text(repository.source.displayPath)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch scanResult {
        case .success:
            Label("Connected", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .missingBuildFolder:
            Label("No /build folder", systemImage: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .emptyScripts:
            Label("No scripts found", systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
        case .unreachable:
            Label("Unreachable", systemImage: "wifi.slash")
                .foregroundStyle(.red)
        case nil:
            if isScanning {
                ProgressView().controlSize(.small)
            }
        }
    }

    @ViewBuilder
    private var buildTab: some View {
        switch scanResult {
        case .success(let scripts):
            GroupBox("Available Build Scripts") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(scripts) { script in
                        HStack {
                            Image(systemName: "play.circle")
                            Text(script.label).font(.body.weight(.medium))
                            Spacer()
                            Text(script.fileName)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
                    }
                    Text("Detected, not yet runnable — execution wiring is Phase 2.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
        case .missingBuildFolder:
            ContentUnavailableView(
                "No /build Folder Found",
                systemImage: "folder.badge.questionmark",
                description: Text("This repository doesn't have a /build folder at its root.")
            )
        case .emptyScripts:
            ContentUnavailableView(
                "No Build Scripts Found",
                systemImage: "doc.text.magnifyingglass",
                description: Text("No .sh files found in /build/scripts/.")
            )
        case .unreachable(let message):
            ContentUnavailableView(
                "Repository Unreachable",
                systemImage: "wifi.slash",
                description: Text(message)
            )
        case nil:
            ProgressView("Scanning…")
        }
    }

    private func comingSoon(_ note: String) -> some View {
        ContentUnavailableView("Coming Soon", systemImage: "hammer", description: Text(note))
    }

    private func scan() async {
        isScanning = true
        switch repository.source {
        case .local(let path):
            scanResult = BuildScriptScanner.scanLocal(path: path)
        case .github(let url):
            scanResult = await BuildScriptScanner.scanGitHub(urlString: url)
        }
        isScanning = false
    }
}
