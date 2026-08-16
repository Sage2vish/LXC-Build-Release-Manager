import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var store = RepositoryStore()
    @StateObject private var historyStore = BuildHistoryStore()
    @StateObject private var runners = BuildRunnerRegistry()
    @State private var isAddingRepository = false
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let repository = store.selectedRepository {
                RepositoryDetailView(
                    repository: repository,
                    store: store,
                    historyStore: historyStore,
                    runner: runners.runner(for: repository.id)
                )
                .id(repository.id)
            } else {
                ContentUnavailableView(
                    "Select a Repository",
                    systemImage: "shippingbox",
                    description: Text("Choose a repository from the sidebar, or add one to begin.")
                )
                .background(.background)
            }
        }
        .safeAreaInset(edge: .bottom) {
            StatusBar(repository: store.selectedRepository)
        }
        .sheet(isPresented: $isAddingRepository) {
            AddRepositorySheet(store: store, isPresented: $isAddingRepository)
        }
    }

    private var sortedRepositories: [Repository] {
        store.repositories.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            return lhs.lastAccessed > rhs.lastAccessed
        }
    }

    private var recentRepositories: [Repository] {
        Array(store.repositories.sorted { $0.lastAccessed > $1.lastAccessed }.prefix(5))
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
            Section {
                ForEach(sortedRepositories) { repository in
                    RepositoryRow(repository: repository, store: store)
                        .tag(repository.id)
                }
            } header: {
                HStack {
                    Text("Repositories")
                    Spacer()
                    Button {
                        isAddingRepository = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.borderless)
                    .help("Add Repository")
                }
            }

            if !recentRepositories.isEmpty {
                Section("Recent Repositories") {
                    ForEach(recentRepositories) { repository in
                        RecentRepositoryRow(repository: repository, store: store)
                    }
                }
            }
        }
        .navigationTitle("Build Manager")
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Divider()
                Button {
                    if let path = presentLocalFolderPickerPath() {
                        store.addLocalRepository(path: path)
                    }
                } label: {
                    Label("Open Repository…", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    openSettings()
                } label: {
                    Label("Preferences", systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(.bar)
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

private func presentLocalFolderPickerPath() -> String? {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.prompt = "Open Repository"
    guard panel.runModal() == .OK, let url = panel.url else { return nil }
    return url.path
}

private struct StatusBar: View {
    let repository: Repository?

    private var branch: String {
        guard let repository, let branch = GitBranchReader.currentBranch(for: repository) else { return "—" }
        return branch
    }

    var body: some View {
        HStack(spacing: 20) {
            statusItem("Repository", repository?.name ?? "—")
            statusItem("Branch", branch)
            statusItem("Platform", "macOS")
            statusItem("Auto-detect", "Enabled")
            Spacer()
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
        .overlay(alignment: .top) { Divider() }
    }

    private func statusItem(_ label: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text("\(label):").foregroundStyle(.secondary)
            Text(value)
        }
    }
}

private struct RecentRepositoryRow: View {
    let repository: Repository
    @ObservedObject var store: RepositoryStore

    var body: some View {
        Button {
            store.select(repository)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: repository.source.isLocal ? "folder" : "chevron.left.forwardslash.chevron.right")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(repository.name).font(.subheadline)
                    Text("Opened \(repository.lastAccessed.relativeDescription)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct RepositoryRow: View {
    let repository: Repository
    @ObservedObject var store: RepositoryStore

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: repository.source.isLocal ? "folder" : "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(.secondary)
                    Text(repository.name)
                        .font(.headline)
                }
                Text(repository.source.displayPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("Last accessed \(repository.lastAccessed.relativeDescription)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 4)
            VStack(spacing: 6) {
                Button {
                    store.togglePin(repository)
                } label: {
                    Image(systemName: repository.isPinned ? "pin.fill" : "pin")
                }
                .buttonStyle(.borderless)
                .help(repository.isPinned ? "Unpin" : "Pin")

                Button {
                    store.remove(repository)
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Remove from list")
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AddRepositorySheet: View {
    @ObservedObject var store: RepositoryStore
    @Binding var isPresented: Bool
    @State private var githubURL: String = ""

    private var trimmedURL: String {
        githubURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValidGitHubURL: Bool {
        guard let url = URL(string: trimmedURL), let host = url.host, host.contains("github.com") else { return false }
        return url.pathComponents.filter { $0 != "/" }.count >= 2
    }

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
                if !trimmedURL.isEmpty && !isValidGitHubURL {
                    Text("Enter a full GitHub repo URL, like https://github.com/user/repo")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button("Add GitHub Repository") {
                    store.addGitHubRepository(urlString: trimmedURL)
                    isPresented = false
                }
                .disabled(!isValidGitHubURL)
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
        guard let path = presentLocalFolderPickerPath() else { return }
        store.addLocalRepository(path: path)
        isPresented = false
    }
}

private struct DisplayLine: Identifiable, Hashable {
    let id: UUID
    let timestampText: String
    let text: String
}

private enum LogFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case errors = "Errors"
    case warnings = "Warnings"
    case info = "Info"
    var id: String { rawValue }

    func matches(_ text: String) -> Bool {
        let errorWords = ["error", "Error", "ERROR", "failed", "Failed"]
        let warningWords = ["warning", "Warning", "WARNING"]
        switch self {
        case .all: return true
        case .errors: return errorWords.contains { text.contains($0) }
        case .warnings: return warningWords.contains { text.contains($0) }
        case .info:
            return !errorWords.contains { text.contains($0) } && !warningWords.contains { text.contains($0) }
        }
    }
}

private func displayLines(from logLines: [LogLine]) -> [DisplayLine] {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return logLines.map { DisplayLine(id: $0.id, timestampText: formatter.string(from: $0.timestamp), text: $0.text) }
}

private func displayLines(fromFileContent content: String) -> [DisplayLine] {
    content
        .split(separator: "\n", omittingEmptySubsequences: false)
        .filter { !$0.hasPrefix("#") && !$0.isEmpty }
        .map { line -> DisplayLine in
            if line.hasPrefix("["), let closeBracket = line.firstIndex(of: "]") {
                let timestamp = String(line[line.index(after: line.startIndex)..<closeBracket])
                let rest = line[line.index(after: closeBracket)...].trimmingCharacters(in: .whitespaces)
                return DisplayLine(id: UUID(), timestampText: timestamp, text: String(rest))
            }
            return DisplayLine(id: UUID(), timestampText: "", text: String(line))
        }
}

private struct LogPane: View {
    let title: String
    let lines: [DisplayLine]
    var onExport: (() -> Void)?

    @State private var searchText = ""
    @State private var filter: LogFilter = .all
    @State private var currentMatchIndex = 0

    private var filtered: [DisplayLine] {
        lines.filter { filter.matches($0.text) }
    }

    private var matchIDs: [UUID] {
        guard !searchText.isEmpty else { return [] }
        return filtered.filter { $0.text.localizedCaseInsensitiveContains(searchText) }.map(\.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Picker("", selection: $filter) {
                    ForEach(LogFilter.allCases) { item in Text(item.rawValue).tag(item) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 260)
                if let onExport {
                    Button { onExport() } label: { Label("Export", systemImage: "square.and.arrow.down") }
                        .disabled(lines.isEmpty)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search log…", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, _ in currentMatchIndex = 0 }
                if !searchText.isEmpty {
                    Text(matchIDs.isEmpty ? "0 matches" : "\(currentMatchIndex + 1) of \(matchIDs.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button { step(-1) } label: { Image(systemName: "chevron.up") }
                        .disabled(matchIDs.isEmpty)
                    Button { step(1) } label: { Image(systemName: "chevron.down") }
                        .disabled(matchIDs.isEmpty)
                }
            }
            .padding(6)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(filtered) { line in
                            HStack(alignment: .top, spacing: 8) {
                                Text(line.timestampText)
                                    .foregroundStyle(.white.opacity(0.55))
                                Text(line.text)
                                    .textSelection(.enabled)
                            }
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                !searchText.isEmpty && line.text.localizedCaseInsensitiveContains(searchText)
                                    ? Color.yellow.opacity(0.3) : .clear
                            )
                            .id(line.id)
                        }
                        if filtered.isEmpty {
                            Text("No log lines to show.")
                                .foregroundStyle(.white.opacity(0.6))
                                .padding()
                        }
                    }
                    .padding(8)
                }
                .frame(minHeight: 220, maxHeight: 420)
                .background(Color.black.opacity(0.88))
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: currentMatchIndex) { _, newValue in
                    guard matchIDs.indices.contains(newValue) else { return }
                    withAnimation { proxy.scrollTo(matchIDs[newValue], anchor: .center) }
                }
            }
        }
    }

    private func step(_ delta: Int) {
        guard !matchIDs.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + delta + matchIDs.count) % matchIDs.count
    }
}

private struct RepositoryDetailView: View {
    let repository: Repository
    @ObservedObject var store: RepositoryStore
    @ObservedObject var historyStore: BuildHistoryStore
    @ObservedObject var runner: BuildRunner

    @State private var selectedTab: DetailTab = .build
    @State private var scanResult: BuildScanResult?
    @State private var isScanning = false
    @State private var selectedLogRecordID: BuildRecord.ID?
    @State private var showInspector = true

    enum DetailTab: String, CaseIterable, Identifiable {
        case build = "Build"
        case logs = "Logs"
        case history = "History"
        case overview = "Overview"
        case settings = "Settings"
        var id: String { rawValue }
    }

    private var records: [BuildRecord] { historyStore.records(for: repository.id) }
    private var stats: RepositoryStats { historyStore.stats(for: repository.id) }

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
                    case .build: buildTab
                    case .logs: logsTab
                    case .history: historyTab
                    case .overview: overviewTab
                    case .settings: settingsTab
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
            ToolbarItem {
                Button {
                    showInspector.toggle()
                } label: {
                    Label("Toggle Build Panel", systemImage: "sidebar.right")
                }
            }
        }
        .inspector(isPresented: $showInspector) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    buildStatusCard
                    buildHistoryCard
                    quickActionsCard
                }
                .padding(16)
            }
            .inspectorColumnWidth(min: 240, ideal: 280, max: 340)
        }
    }

    // MARK: Inspector — Build Status / History / Quick Actions

    private var buildStatusCard: some View {
        GroupBox("Build Status") {
            VStack(alignment: .leading, spacing: 6) {
                if runner.isRunning, let script = runner.runningScript {
                    Label("In Progress", systemImage: "circle.dotted").foregroundStyle(.blue)
                    Text(script.label).font(.headline)
                    if let startedAt = runner.startedAt {
                        LabeledContent("Started At", value: startedAt.formatted(date: .omitted, time: .standard))
                    }
                    LabeledContent("Duration", value: durationDescription(runner.duration))
                    Button("Stop Build", role: .destructive) { runner.cancel() }
                        .frame(maxWidth: .infinity)
                } else if let mostRecent = stats.mostRecent {
                    Label(statusLabel(mostRecent.status), systemImage: statusSymbolName(mostRecent.status))
                        .foregroundStyle(statusColor(mostRecent.status))
                    Text(mostRecent.scriptLabel).font(.headline)
                    LabeledContent("Duration", value: durationDescription(mostRecent.durationSeconds))
                } else {
                    Text("No builds run yet.").foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }

    private var buildHistoryCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                if records.isEmpty {
                    Text("No builds yet.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(records.prefix(5)) { record in
                        HStack {
                            statusIcon(record.status)
                            Text(record.scriptLabel).font(.caption)
                            Spacer()
                            Text(durationDescription(record.durationSeconds))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        } label: {
            HStack {
                Text("Build History")
                Spacer()
                Button("View All") { selectedTab = .history }
                    .buttonStyle(.link)
                    .font(.caption)
            }
        }
    }

    private var quickActionsCard: some View {
        GroupBox("Quick Actions") {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    openLogsFolder()
                } label: {
                    Label("Open Logs Folder", systemImage: "folder")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(!repository.source.isLocal)

                Button {
                    exportCurrentLog()
                } label: {
                    Label("Export Current Log", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(!runner.isRunning && selectedRecord == nil)
            }
            .buttonStyle(.bordered)
            .padding(.vertical, 4)
        }
    }

    private func statusLabel(_ status: BuildStatus) -> String {
        switch status {
        case .success: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        case .running: return "In Progress"
        }
    }

    private func statusSymbolName(_ status: BuildStatus) -> String {
        switch status {
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .cancelled: return "slash.circle.fill"
        case .running: return "circle.dotted"
        }
    }

    private func statusColor(_ status: BuildStatus) -> Color {
        switch status {
        case .success: return .green
        case .failed: return .red
        case .cancelled: return .orange
        case .running: return .blue
        }
    }

    private func openLogsFolder() {
        guard let directory = LogFileService.logsDirectoryURL(for: repository) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        NSWorkspace.shared.open(directory)
    }

    private func exportCurrentLog() {
        if runner.isRunning, let script = runner.runningScript {
            let content = LogFileService.formattedContent(
                lines: runner.logLines,
                script: script,
                status: .running,
                startedAt: runner.startedAt ?? Date()
            )
            LogFileService.export(content: content, suggestedName: "\(script.fileName)-current.log")
        } else if let record = selectedRecord {
            LogFileService.export(content: logContent(for: record), suggestedName: record.logFileName)
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
            Label("Connected", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
        case .missingBuildFolder:
            Label("No /build folder", systemImage: "xmark.circle.fill").foregroundStyle(.red)
        case .emptyScripts:
            Label("No scripts found", systemImage: "exclamationmark.circle.fill").foregroundStyle(.orange)
        case .unreachable:
            Label("Unreachable", systemImage: "wifi.slash").foregroundStyle(.red)
        case nil:
            if isScanning { ProgressView().controlSize(.small) }
        }
    }

    // MARK: Build

    @ViewBuilder
    private var buildTab: some View {
        switch scanResult {
        case .success(let scripts):
            GroupBox("Available Build Scripts") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(scripts) { script in
                        scriptRow(script)
                    }
                    if !repository.source.isLocal {
                        Text("Execution requires a local repository — GitHub-sourced repos can only detect scripts for now.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }

            if runner.isRunning || !runner.logLines.isEmpty {
                LogPane(title: "Live Output", lines: displayLines(from: runner.logLines))
            }
        case .missingBuildFolder:
            ContentUnavailableView("No /build Folder Found", systemImage: "folder.badge.questionmark", description: Text("This repository doesn't have a /build folder at its root."))
        case .emptyScripts:
            ContentUnavailableView("No Build Scripts Found", systemImage: "doc.text.magnifyingglass", description: Text("No .sh files found in /build/scripts/."))
        case .unreachable(let message):
            ContentUnavailableView("Repository Unreachable", systemImage: "wifi.slash", description: Text(message))
        case nil:
            ProgressView("Scanning…")
        }
    }

    private func scriptRow(_ script: BuildScript) -> some View {
        let lastRun = historyStore.lastRun(for: repository.id, scriptFileName: script.fileName)
        let isThisRunning = runner.isRunning && runner.runningScript?.fileName == script.fileName

        return HStack {
            Image(systemName: "play.circle")
            VStack(alignment: .leading, spacing: 2) {
                Text(script.label).font(.body.weight(.medium))
                Text(lastRunDescription(lastRun, isRunning: isThisRunning))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(script.fileName)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            if isThisRunning {
                ProgressView().controlSize(.small)
                Button("Cancel") { runner.cancel() }
                    .buttonStyle(.bordered)
            } else {
                Button("Run") {
                    runner.start(script: script, repository: repository, historyStore: historyStore)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!repository.source.isLocal || runner.isRunning)
            }
        }
        .padding(8)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
    }

    private func lastRunDescription(_ record: BuildRecord?, isRunning: Bool) -> String {
        if isRunning { return "Building…" }
        guard let record else { return "Never run" }
        let icon = record.status == .success ? "✓" : (record.status == .cancelled ? "⊘" : "✗")
        return "Last run: \(record.startedAt.relativeDescription) \(icon)"
    }

    // MARK: Logs

    private var logsTab: some View {
        Group {
            if runner.isRunning {
                LogPane(title: "Live Output — \(runner.runningScript?.label ?? "")", lines: displayLines(from: runner.logLines))
            } else if let record = selectedRecord {
                LogPane(
                    title: "\(record.scriptLabel) — \(record.startedAt.formatted(date: .abbreviated, time: .shortened))",
                    lines: logLines(for: record),
                    onExport: {
                        LogFileService.export(content: logContent(for: record), suggestedName: record.logFileName)
                    }
                )
            } else {
                ContentUnavailableView("No Logs Yet", systemImage: "doc.text", description: Text("Run a build to see live output and saved logs here."))
            }
        }
    }

    private var selectedRecord: BuildRecord? {
        if let id = selectedLogRecordID, let match = records.first(where: { $0.id == id }) {
            return match
        }
        return records.first
    }

    private func logContent(for record: BuildRecord) -> String {
        LogFileService.read(fileName: record.logFileName, repository: repository) ?? ""
    }

    private func logLines(for record: BuildRecord) -> [DisplayLine] {
        displayLines(fromFileContent: logContent(for: record))
    }

    // MARK: History

    private var historyTab: some View {
        GroupBox("Build History") {
            if records.isEmpty {
                Text("No builds run yet for this repository.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(records) { record in
                        Button {
                            selectedLogRecordID = record.id
                            selectedTab = .logs
                        } label: {
                            HStack {
                                statusIcon(record.status)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(record.scriptLabel).font(.body.weight(.medium))
                                    Text(record.startedAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(durationDescription(record.durationSeconds))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func statusIcon(_ status: BuildStatus) -> some View {
        switch status {
        case .success: return Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
        case .failed: return Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
        case .cancelled: return Image(systemName: "slash.circle.fill").foregroundStyle(.orange)
        case .running: return Image(systemName: "circle.dotted").foregroundStyle(.blue)
        }
    }

    // MARK: Overview

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Repository") {
                VStack(alignment: .leading, spacing: 6) {
                    LabeledContent("Name", value: repository.name)
                    LabeledContent("Path/URL", value: repository.source.displayPath)
                    LabeledContent("Connection") {
                        statusBadge
                    }
                    LabeledContent("Total Builds", value: "\(stats.totalBuilds)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }

            HStack(spacing: 12) {
                statCard(title: "Total Builds", value: "\(stats.totalBuilds)")
                statCard(title: "Success Rate", value: stats.totalBuilds > 0 ? "\(Int(stats.successRate * 100))%" : "—")
                statCard(title: "Avg Duration", value: stats.totalBuilds > 0 ? durationDescription(stats.averageDuration) : "—")
            }

            if let mostRecent = stats.mostRecent {
                Text("Most recently run: \(mostRecent.scriptLabel) — \(mostRecent.startedAt.relativeDescription)")
                    .font(.callout)
            }
            if let lastFailed = stats.lastFailed {
                Text("Last failed build: \(lastFailed.scriptLabel) — \(lastFailed.startedAt.relativeDescription)")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
    }

    private func statCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title2.weight(.semibold))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
    }

    private func durationDescription(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainder = Int(seconds) % 60
        return minutes > 0 ? "\(minutes)m \(remainder)s" : "\(remainder)s"
    }

    // MARK: Settings

    private var settingsTab: some View {
        GroupBox("Repository Settings") {
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Pinned", isOn: Binding(
                    get: { repository.isPinned },
                    set: { _ in store.togglePin(repository) }
                ))
                Button("Remove from List", role: .destructive) {
                    store.remove(repository)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
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

private extension Date {
    var relativeDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
