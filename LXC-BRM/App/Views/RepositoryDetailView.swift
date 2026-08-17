import SwiftUI
import AppKit

/// The right-hand repository workspace: header, the Build/Logs/History/Overview/Settings tabs,
/// and the Detail View Window inspector.
///
/// Extracted from `ContentView` so the app shell is composition only. Its dependency surface is
/// still wide - see the refactor plan's section 04 for the remaining split into per-tab views.
struct RepositoryDetailView: View {
    let repository: Repository
    @ObservedObject var store: RepositoryStore
    @ObservedObject var historyStore: BuildHistoryStore
    @ObservedObject var workspaceStateStore: BuildWorkspaceStateStore
    @ObservedObject var preferencesStore: PreferencesStore
    @ObservedObject var runners: BuildRunnerRegistry
    @ObservedObject var runner: BuildRunner

    @State private var selectedTab: DetailTab
    @State private var scanResult: BuildScanResult?
    @State private var isScanning = false
    @State private var selectedLogRecordID: BuildRecord.ID?
    /// Shared with the "Show Detail View Window (Right Side)" menu item, so the toolbar
    /// button and the View menu can never disagree about the panel state.
    private var showInspector: Binding<Bool> { preferencesStore.binding(\.showDetailInspector) }
    @State private var buildTabError: BuildWorkspaceError?
    @State private var isAutoFindingScripts = false
    @State private var gitHubURLDraft = ""
    @State private var gitHubURLError: String?
    @State private var pickerError: String?

    init(
        repository: Repository,
        store: RepositoryStore,
        historyStore: BuildHistoryStore,
        workspaceStateStore: BuildWorkspaceStateStore,
        preferencesStore: PreferencesStore,
        runners: BuildRunnerRegistry,
        runner: BuildRunner,
        initialTab: DetailTab = .build
    ) {
        self.repository = repository
        self.store = store
        self.historyStore = historyStore
        self.workspaceStateStore = workspaceStateStore
        self._preferencesStore = ObservedObject(wrappedValue: preferencesStore)
        self._runners = ObservedObject(wrappedValue: runners)
        self.runner = runner
        self._selectedTab = State(initialValue: initialTab)
    }

    enum DetailTab: String, CaseIterable, Identifiable {
        case build = "Build"
        case logs = "Logs"
        case history = "History"
        case overview = "Overview"
        case settings = "Settings"
        var id: String { rawValue }

        init(_ launchTab: DefaultLaunchTab) {
            switch launchTab {
            case .build: self = .build
            case .logs: self = .logs
            case .history: self = .history
            case .overview: self = .overview
            }
        }
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
        .sheet(isPresented: $isAutoFindingScripts) {
            if let rootPath = repository.localPath {
                AutoFindScriptsSheet(
                    repositoryRootPath: rootPath,
                    existingPaths: existingScriptPaths,
                    onAdd: { paths in importScripts(paths) },
                    isPresented: $isAutoFindingScripts
                )
            }
        }
        .task(id: repository.id) { await scan() }
        .onChange(of: runner.finishedAt) { _, newValue in
            guard newValue != nil else { return }
            if preferencesStore.preferences.defaultBehaviorAfterBuildCompletes == "Switch to History" {
                selectedTab = .history
            }
        }
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await scan() }
                } label: {
                    Label("Rescan", systemImage: "arrow.clockwise")
                }
                .disabled(isScanning || runner.isRunning)
                .keyboardShortcut("r", modifiers: [.command])
            }
            ToolbarItem {
                Button {
                    showInspector.wrappedValue.toggle()
                } label: {
                    Label("Toggle Detail View", systemImage: "sidebar.right")
                }
            }
        }
        .inspector(isPresented: showInspector) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Parameters and the selected script's full path moved here from the
                    // centre column, so the Detail View Window carries the detail.
                    if case .success(let scripts) = scanResult,
                       let selectedScript = selectedScript(in: scripts) {
                        selectedScriptPathCard(for: selectedScript)
                        buildParametersPanel(for: selectedScript)
                    }
                    buildStatusCard
                    buildHistoryCard
                    quickActionsCard
                }
                .padding(16)
            }
            // Wide enough to host parameter controls and a wrapped command preview.
            .inspectorColumnWidth(min: 320, ideal: 460, max: 900)
        }
    }

    /// Full path of the selected script, wrapped rather than truncated. The scripts table
    /// only shows the folder name, so this is where the complete path is readable.
    private func selectedScriptPathCard(for script: BuildScript) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 6) {
                Text("Selected Script").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text(script.label)
                    .font(.body.weight(.medium))
                Label(script.location.label, systemImage: "folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Full path").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Text(script.path)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 6))
                    .accessibilityLabel("Full script path: \(script.path)")
                Button {
                    copy(script.path)
                } label: {
                    Label("Copy Path", systemImage: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
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
                    LabeledContent("Duration", value: BuildPresentation.durationDescription(runner.duration))
                    Button("Stop Build", role: .destructive) { runner.cancel(preferences: preferencesStore.preferences) }
                        .frame(maxWidth: .infinity)
                } else if let mostRecent = stats.mostRecent {
                    Label(statusLabel(mostRecent.status), systemImage: BuildPresentation.symbolName(for: mostRecent.status))
                        .foregroundStyle(BuildPresentation.color(for: mostRecent.status))
                    Text(mostRecent.scriptLabel).font(.headline)
                    LabeledContent("Duration", value: BuildPresentation.durationDescription(mostRecent.durationSeconds))
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
                            Text(BuildPresentation.durationDescription(record.durationSeconds))
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
                .disabled(!hasExportableLog)
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

    private func openLogsFolder() {
        guard let directory = LogFileService.logsDirectoryURL(for: repository) else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        NSWorkspace.shared.open(directory)
    }

    private func exportCurrentLog() {
        if runner.hasOutput {
            exportLiveLog()
        } else if let record = selectedRecord {
            LogFileService.export(content: logContent(for: record), suggestedName: record.logFileName)
        }
    }

    private var hasExportableLog: Bool {
        if runner.hasOutput { return true }
        guard let record = selectedRecord else { return false }
        return !logContent(for: record).isEmpty
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Text(repository.name)
                    .font(.system(size: 24, weight: .semibold))
                statusBadge
                Spacer()
                Button { revealInFinder() } label: {
                    Label("Reveal in Finder", systemImage: "folder")
                }
                .accessibilityLabel("Reveal in Finder")
                .disabled(!repository.source.isLocal)
                Button { openInTerminal() } label: {
                    Label("Open in Terminal", systemImage: "terminal")
                }
                .accessibilityLabel("Open in Terminal")
                .disabled(!repository.source.isLocal)
                Button { copyPath() } label: {
                    Label("Copy Path", systemImage: "doc.on.doc")
                }
                .accessibilityLabel("Copy repository path")
            }
            // Local folder first, GitHub URL below it. Whichever does not apply is omitted
            // entirely rather than rendered blank.
            if let localPath = repository.localPath {
                sourceLine(label: "Local folder", value: localPath, icon: "folder")
            }
            if let gitHubURL = repository.resolvedGitHubURL {
                sourceLine(label: "GitHub", value: gitHubURL, icon: "link")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sourceLine(label: String, value: String, icon: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(label):")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
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
            // Parameters and the resolved command now live in the Detail View Window
            // (right panel). The centre column is the scripts table over the live output.
            buildScriptsPanel(scripts)
            buildOutputPanel
        case .missingBuildFolder:
            VStack(alignment: .leading, spacing: 16) {
                ContentUnavailableView("No /build Folder Found", systemImage: "folder.badge.questionmark", description: Text("This repository doesn't have a /build folder at its root."))
                buildScriptsFallbackActions
                buildOutputPanel
            }
        case .emptyScripts:
            VStack(alignment: .leading, spacing: 16) {
                ContentUnavailableView("No Build Scripts Found", systemImage: "doc.text.magnifyingglass", description: Text("No runnable scripts were found in /build/scripts/."))
                buildScriptsFallbackActions
                buildOutputPanel
            }
        case .unreachable(let message):
            VStack(alignment: .leading, spacing: 16) {
                ContentUnavailableView("Repository Unreachable", systemImage: "wifi.slash", description: Text(message))
                Button("Retry Scan") { Task { await scan() } }
                buildOutputPanel
            }
        case nil:
            ContentUnavailableView("Scanning Build Scripts", systemImage: "magnifyingglass", description: Text("Checking the repository for runnable build scripts."))
        }
    }

    private func buildScriptsPanel(_ scripts: [BuildScript]) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Available Build Scripts").font(.headline)
                        Text("Auto-detected from /\(preferencesStore.preferences.defaultBuildFolderName)/\(preferencesStore.preferences.scriptsSubdirectory)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { isAutoFindingScripts = true } label: {
                        Label("Auto Find", systemImage: "sparkle.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Auto Find build scripts")
                    .disabled(!repository.source.isLocal || isScanning)
                    .accessibilityHint("Search every folder in this repository for shell scripts.")

                    Menu {
                        Button { addBuildScript() } label: {
                            Label("Add Build Script…", systemImage: "doc")
                        }
                        .disabled(!repository.source.isLocal)
                        Button { addBuildScriptFolder() } label: {
                            Label("Add Build Script Folder…", systemImage: "folder.badge.plus")
                        }
                        .disabled(!repository.source.isLocal)
                    } label: {
                        Label("Add Build Script", systemImage: "plus")
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                    .disabled(!repository.source.isLocal)
                    .accessibilityHint("Add a single shell script, or every script in a folder.")

                    Button { Task { await scan() } } label: {
                        Label("Refresh Scripts", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Refresh build scripts")
                    .disabled(isScanning || runner.isRunning)
                }

                if let pickerError {
                    Label(pickerError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                if let buildTabError {
                    Label(buildTabError.errorDescription ?? "Build validation failed.", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .accessibilityLabel("Build error: \(buildTabError.errorDescription ?? "Unknown error")")
                }
                if runners.runningCount >= preferencesStore.preferences.maxConcurrentBuilds {
                    Label("Maximum concurrent builds reached. Stop one build before starting another.", systemImage: "exclamationmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !repository.source.isLocal {
                    Label("GitHub repositories can be scanned, but must be cloned locally before they can be run.", systemImage: "icloud.slash")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Text("Script").frame(minWidth: 200, maxWidth: .infinity, alignment: .leading)
                    Text("Source").frame(width: 122, alignment: .leading)
                    Text("Parameters").frame(width: 108, alignment: .leading)
                    Text("Last run").frame(width: 126, alignment: .leading)
                    Text("Actions").frame(width: 118, alignment: .leading)
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)

                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(scripts) { script in
                            scriptRow(script)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(minHeight: 130, maxHeight: 300)
                .accessibilityLabel("Available build scripts")

                HStack(spacing: 14) {
                    Label("Standard folder", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                    Label("In repository", systemImage: "folder.fill").foregroundStyle(.blue)
                    Label("Outside repository", systemImage: "externaldrive.fill").foregroundStyle(.orange)
                    Label("Unavailable", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 5)
        }
    }

    private var buildScriptsFallbackActions: some View {
        HStack {
            Button { addBuildScript() } label: {
                Label("Add Build Script", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!repository.source.isLocal)
            Button { addBuildScriptFolder() } label: {
                Label("Add Folder", systemImage: "folder.badge.plus")
            }
            .buttonStyle(.bordered)
            .disabled(!repository.source.isLocal)
            Button { isAutoFindingScripts = true } label: {
                Label("Auto Find", systemImage: "sparkle.magnifyingglass")
            }
            .buttonStyle(.bordered)
            .disabled(!repository.source.isLocal)
            Button { Task { await scan() } } label: {
                Label("Refresh Scripts", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }

    private func scriptRow(_ script: BuildScript) -> some View {
        let lastRun = historyStore.lastRun(for: repository.id, scriptFileName: script.fileName)
        let isThisRunning = runner.isRunning && runner.runningScript?.fileName == script.fileName
        return BuildScriptTableRow(
            script: script,
            lastRunText: lastRunDescription(lastRun, isRunning: isThisRunning),
            lastRunColor: lastRunColor(lastRun, isRunning: isThisRunning),
            isSelected: selectedScriptID == script.id,
            isRunning: isThisRunning,
            canRun: canRun(script),
            onSelect: { select(script) },
            onRun: { run(script) },
            onStop: { runner.cancel(preferences: preferencesStore.preferences) },
            onReveal: { reveal(script: script) },
            onCopyPath: { copy(script.path) }
        )
    }

    private func lastRunDescription(_ record: BuildRecord?, isRunning: Bool) -> String {
        BuildScreenRules.lastRunDescription(
            record: record,
            isRunning: isRunning,
            isStopping: runner.phase == .stopping
        )
    }

    private func lastRunColor(_ record: BuildRecord?, isRunning: Bool) -> Color {
        BuildScreenRules.lastRunColor(record: record, isRunning: isRunning)
    }

    private var selectedScriptID: String? {
        workspaceStateStore.state(for: repository.id).selectedScriptID
    }

    private func selectedScript(in scripts: [BuildScript]) -> BuildScript? {
        BuildScreenRules.selectedScript(in: scripts, selectedID: selectedScriptID)
    }

    private func select(_ script: BuildScript) {
        workspaceStateStore.select(scriptID: script.id, for: repository.id)
        buildTabError = nil
    }

    private func canRun(_ script: BuildScript) -> Bool {
        BuildScreenRules.canRun(
            script: script,
            isLocalRepository: repository.source.isLocal,
            isRunnerBusy: runner.isRunning,
            runningCount: runners.runningCount,
            maxConcurrentBuilds: preferencesStore.preferences.maxConcurrentBuilds,
            allowScriptsOutsideRepository: preferencesStore.preferences.allowScriptsOutsideBuildScripts
        )
    }

    private func run(_ script: BuildScript) {
        select(script)
        let values = workspaceStateStore.values(for: script.id, repositoryID: repository.id)
        let validationErrors = BuildCommandBuilder.validate(script: script, values: values)
        guard validationErrors.isEmpty else {
            buildTabError = .validation(validationErrors.joined(separator: "\n"))
            return
        }
        guard runner.start(
            script: script,
            parameters: values,
            repository: repository,
            historyStore: historyStore,
            preferences: preferencesStore.preferences
        ) else {
            buildTabError = runner.lastError
            return
        }
        buildTabError = nil
    }

    private func buildParametersPanel(for script: BuildScript) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Build Parameters").font(.headline)
                        Text(script.fileName)
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if runner.phase == .starting {
                        ProgressView().controlSize(.small)
                        Text("Starting…").font(.caption).foregroundStyle(.secondary)
                    }
                    Button { run(script) } label: {
                        Label(runner.isRunning ? "Build Running" : "Run Build", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canRun(script))
                    .keyboardShortcut(.return, modifiers: [.command])
                    .accessibilityHint("Runs the selected build with the displayed parameter values.")
                }

                if script.parameters.isEmpty {
                    Text("This script does not declare parameters. It will run directly from the repository root.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(BuildCommandBuilder.activeParameters(
                        for: script,
                        values: workspaceStateStore.values(for: script.id, repositoryID: repository.id)
                    )) { parameter in
                        parameterControl(parameter, for: script)
                    }
                }

                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resolved Command").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(commandPreview(for: script))
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                        // Wrapped, not truncated — the panel is wide enough to read it now.
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 6))
                        .accessibilityLabel("Resolved build command")
                }
            }
            .padding(.vertical, 5)
        }
    }

    @ViewBuilder
    private func parameterControl(_ parameter: BuildParameterDefinition, for script: BuildScript) -> some View {
        let validationMessage = validationMessage(for: parameter, script: script)
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Text(parameter.label).font(.callout.weight(.medium))
                if parameter.isRequired {
                    Text("Required").font(.caption2.weight(.semibold)).foregroundStyle(.red)
                }
                if !parameter.helpText.isEmpty {
                    Text(parameter.helpText).font(.caption).foregroundStyle(.secondary)
                }
            }

            switch parameter.kind {
            case .text, .number:
                TextField(parameter.placeholder.isEmpty ? parameter.label : parameter.placeholder, text: parameterBinding(for: parameter, script: script))
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel(parameter.label)
            case .boolean:
                Toggle(parameter.label, isOn: booleanBinding(for: parameter, script: script))
                    .toggleStyle(.switch)
                    .accessibilityLabel(parameter.label)
            case .choice:
                Picker(parameter.label, selection: parameterBinding(for: parameter, script: script)) {
                    if !parameter.isRequired {
                        Text("Not set").tag("")
                    }
                    ForEach(parameter.options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel(parameter.label)
            case .path:
                HStack {
                    TextField(parameter.placeholder.isEmpty ? "Choose a file or folder" : parameter.placeholder, text: parameterBinding(for: parameter, script: script))
                        .textFieldStyle(.roundedBorder)
                    Button("Choose…") { choosePath(for: parameter, script: script) }
                        .buttonStyle(.bordered)
                }
                .accessibilityElement(children: .contain)
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Validation error: \(validationMessage)")
            }
        }
        .padding(8)
        .background(validationMessage == nil ? Color.clear : Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
    }

    private func parameterBinding(for parameter: BuildParameterDefinition, script: BuildScript) -> Binding<String> {
        Binding(
            get: {
                workspaceStateStore.values(for: script.id, repositoryID: repository.id)[parameter.key] ?? parameter.defaultValue
            },
            set: { value in
                var values = workspaceStateStore.values(for: script.id, repositoryID: repository.id)
                values[parameter.key] = value
                workspaceStateStore.save(values: values, for: script.id, repositoryID: repository.id)
                buildTabError = nil
            }
        )
    }

    private func booleanBinding(for parameter: BuildParameterDefinition, script: BuildScript) -> Binding<Bool> {
        Binding(
            get: { parameterBinding(for: parameter, script: script).wrappedValue == "true" },
            set: { parameterBinding(for: parameter, script: script).wrappedValue = $0 ? "true" : "false" }
        )
    }

    private func validationMessage(for parameter: BuildParameterDefinition, script: BuildScript) -> String? {
        BuildCommandBuilder.validate(
            script: script,
            values: workspaceStateStore.values(for: script.id, repositoryID: repository.id)
        ).first { $0.localizedCaseInsensitiveContains(parameter.label) }
    }

    private func commandPreview(for script: BuildScript) -> String {
        let values = workspaceStateStore.values(for: script.id, repositoryID: repository.id)
        return (try? BuildCommandBuilder.invocation(for: script, values: values).commandPreview)
            ?? script.path
    }

    private var buildOutputPanel: some View {
        LogPane(
            title: runner.isRunning ? "Live Output — \(runner.runningScript?.label ?? "Build")" : "Live Output",
            lines: LogPresentation.displayLines(from: runner.logLines),
            preferences: preferencesStore.preferences,
            onExport: { exportLiveLog() },
            onOpenInWindow: {
                openLogWindow(
                    title: runner.isRunning ? "Live Output — \(runner.runningScript?.label ?? "Build")" : "Live Output",
                    lines: LogPresentation.displayLines(from: runner.logLines),
                    onExport: { exportLiveLog() }
                )
            },
            onStop: { runner.cancel(preferences: preferencesStore.preferences) },
            onClear: { confirmThenClearOutput() },
            isRunning: runner.isRunning
        )
    }

    private func exportLiveLog() {
        guard let script = runner.runningScript ?? currentBuildScript else { return }
        let status: BuildStatus = switch runner.phase {
        case .succeeded: .success
        case .failed: .failed
        case .cancelled: .cancelled
        default: .running
        }
        let content = LogFileService.formattedContent(
            lines: runner.logLines,
            script: script,
            status: status,
            startedAt: runner.startedAt ?? Date(),
            timestampFormat: preferencesStore.preferences.timestampFormat
        )
        LogFileService.export(content: content, suggestedName: "\(script.fileName)-current.log")
    }

    private var currentBuildScript: BuildScript? {
        guard case .success(let scripts) = scanResult else { return nil }
        return selectedScript(in: scripts)
    }

    private func choosePath(for parameter: BuildParameterDefinition, script: BuildScript) {
        guard let path = presentBuildParameterPath() else { return }
        parameterBinding(for: parameter, script: script).wrappedValue = path
    }

    // MARK: Logs

    private var logsTab: some View {
        Group {
            if runner.isRunning {
                LogPane(
                    title: "Live Output — \(runner.runningScript?.label ?? "")",
                    lines: LogPresentation.displayLines(from: runner.logLines),
                    preferences: preferencesStore.preferences,
                    onExport: { exportLiveLog() },
                    onOpenInWindow: {
                        openLogWindow(
                            title: "Live Output — \(runner.runningScript?.label ?? "")",
                            lines: LogPresentation.displayLines(from: runner.logLines),
                            onExport: { exportLiveLog() }
                        )
                    },
                    onStop: { runner.cancel(preferences: preferencesStore.preferences) },
                    onClear: { confirmThenClearOutput() },
                    isRunning: runner.isRunning
                )
            } else if let record = selectedRecord {
                LogPane(
                    title: "\(record.scriptLabel) — \(record.startedAt.formatted(date: .abbreviated, time: .shortened))",
                    lines: logLines(for: record),
                    preferences: preferencesStore.preferences,
                    onExport: {
                        LogFileService.export(content: logContent(for: record), suggestedName: record.logFileName)
                    },
                    onOpenInWindow: {
                        openLogWindow(
                            title: "\(record.scriptLabel) — \(record.startedAt.formatted(date: .abbreviated, time: .shortened))",
                            lines: logLines(for: record),
                            onExport: {
                                LogFileService.export(content: logContent(for: record), suggestedName: record.logFileName)
                            }
                        )
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
        LogFileService.read(
            fileName: record.logFileName,
            repository: repository,
            encodingName: preferencesStore.preferences.logEncoding
        ) ?? ""
    }

    private func logLines(for record: BuildRecord) -> [DisplayLine] {
        LogPresentation.displayLines(fromFileContent: logContent(for: record))
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
                                Text(BuildPresentation.durationDescription(record.durationSeconds))
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
                statCard(title: "Avg Duration", value: stats.totalBuilds > 0 ? BuildPresentation.durationDescription(stats.averageDuration) : "—")
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

    // MARK: Settings

    private var settingsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
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

            // Only a local repository needs this: a GitHub-sourced repo already carries its URL
            // in `source`, so there is nothing supplementary to set.
            if repository.source.isLocal {
                GroupBox("GitHub Origin") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Record the GitHub URL this local folder was cloned from. It appears under the repository name at the top of this screen.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            TextField(
                                "https://github.com/owner/repo",
                                text: $gitHubURLDraft
                            )
                            .textFieldStyle(.roundedBorder)
                            .onSubmit { saveGitHubURL() }

                            Button("Save") { saveGitHubURL() }
                                .disabled(gitHubURLDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                                          == (repository.gitHubURL ?? ""))
                            Button("Clear") {
                                gitHubURLDraft = ""
                                saveGitHubURL()
                            }
                            .disabled(repository.gitHubURL == nil)
                        }
                        if let gitHubURLError {
                            Label(gitHubURLError, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            }
        }
        .onAppear { gitHubURLDraft = repository.gitHubURL ?? "" }
    }

    private func saveGitHubURL() {
        switch GitHubURLValidator.evaluate(gitHubURLDraft) {
        case .cleared:
            store.setGitHubURL("", for: repository)
            gitHubURLError = nil
        case .valid(let url):
            store.setGitHubURL(url, for: repository)
            gitHubURLError = nil
        case .invalid(let message):
            gitHubURLError = message
        }
    }

    private func scan() async {
        isScanning = true
        pickerError = nil
        let preferences = preferencesStore.preferences
        switch repository.source {
        case .local(let path):
            scanResult = BuildScriptScanner.scanLocal(
                path: path,
                options: BuildScanOptions(preferences: preferences),
                additionalScriptPaths: workspaceStateStore.state(for: repository.id).addedScriptPaths
            )
        case .github(let url):
            scanResult = await BuildScriptScanner.scanGitHub(
                urlString: url,
                options: BuildScanOptions(preferences: preferences)
            )
        }
        if case .success(let scripts) = scanResult {
            let savedSelection = workspaceStateStore.state(for: repository.id).selectedScriptID
            if !scripts.contains(where: { $0.id == savedSelection }) {
                workspaceStateStore.select(scriptID: scripts.first?.id, for: repository.id)
            }
        }
        isScanning = false
    }

    private func addBuildScript() {
        guard case .local(let repositoryPath) = repository.source else { return }
        guard let scriptPath = presentBuildScriptPickerPath(repositoryPath: repositoryPath) else { return }
        guard scriptPath.hasSuffix(".sh") || FileManager.default.isExecutableFile(atPath: scriptPath) else {
            pickerError = "Choose a shell script (.sh) or an executable file."
            return
        }

        let isInsideRepository = BuildScriptPathResolver.isWithin(scriptPath, rootPath: repositoryPath)
        guard isInsideRepository || preferencesStore.preferences.allowScriptsOutsideBuildScripts else {
            pickerError = "The selected script is outside this repository. Enable that option in Preferences to add it."
            return
        }

        workspaceStateStore.add(scriptPath: scriptPath, for: repository.id)
        workspaceStateStore.select(
            scriptID: BuildScriptPathResolver.canonicalIdentifier(for: scriptPath),
            for: repository.id
        )
        pickerError = nil
        Task { await scan() }
    }

    /// Script paths already present, so Auto Find can flag duplicates instead of re-adding them.
    private var existingScriptPaths: Set<String> {
        guard case .success(let scripts) = scanResult else { return [] }
        return Set(scripts.map(\.path))
    }

    /// Adds every runnable script in a chosen folder, rather than one file at a time.
    private func addBuildScriptFolder() {
        guard case .local(let repositoryPath) = repository.source else { return }
        guard let folderPath = presentLocalFolderPickerPath() else { return }

        let outcome = BuildScriptFolderImport.resolve(
            folderPath: folderPath,
            repositoryPath: repositoryPath,
            allowOutsideRepository: preferencesStore.preferences.allowScriptsOutsideBuildScripts,
            existingPaths: existingScriptPaths
        )

        guard case .scripts(let scriptPaths) = outcome else {
            pickerError = outcome.errorMessage
            return
        }

        importScripts(scriptPaths)
    }

    /// Shared import path for the folder picker and the Auto Find grid.
    private func importScripts(_ paths: [String]) {
        let newPaths = paths.filter { !existingScriptPaths.contains($0) }
        guard !newPaths.isEmpty else {
            pickerError = "Those scripts are already in this repository."
            return
        }

        for path in newPaths {
            workspaceStateStore.add(scriptPath: path, for: repository.id)
        }
        if let first = newPaths.first {
            workspaceStateStore.select(
                scriptID: BuildScriptPathResolver.canonicalIdentifier(for: first),
                for: repository.id
            )
        }
        pickerError = nil
        Task { await scan() }
    }

    /// Honours the "Confirm before clearing history or logs" preference, which was stored and
    /// shown in Preferences but never consulted — Clear wiped the pane with no confirmation.
    private func confirmThenClearOutput() {
        guard preferencesStore.preferences.confirmBeforeClearing else {
            runner.clearOutput()
            return
        }
        let alert = NSAlert()
        alert.messageText = "Clear Build Output?"
        alert.informativeText = "This clears the visible output. Saved logs and build history are not affected."
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning
        if alert.runModal() == .alertFirstButtonReturn {
            runner.clearOutput()
        }
    }

    private func revealInFinder() {
        guard case .local(let path) = repository.source else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    private func openInTerminal() {
        guard case .local(let path) = repository.source else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Terminal", path]
        try? process.run()
    }

    private func copyPath() {
        copy(repository.source.displayPath)
    }

    private func reveal(script: BuildScript) {
        guard !script.isRemote else { return }
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: script.path)])
    }

    private func copy(_ value: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func openLogWindow(title: String, lines: [DisplayLine], onExport: (() -> Void)? = nil) {
        LogWindowController.shared.show(
            title: title,
            rootView: LogPane(title: title, lines: lines, preferences: preferencesStore.preferences, onExport: onExport)
        )
    }
}

#Preview {
    LogPane(
        title: "Example Log Output",
        lines: [
            DisplayLine(id: UUID(), timestampText: "10:15:01", text: "Build started...", stream: .stdout, ansiColor: nil),
            DisplayLine(id: UUID(), timestampText: "10:15:03", text: "Compiling main.swift", stream: .stdout, ansiColor: nil),
            DisplayLine(id: UUID(), timestampText: "10:15:10", text: "\u{001B}[32mBuild succeeded.\u{001B}[0m", stream: .stdout, ansiColor: .green),
            DisplayLine(id: UUID(), timestampText: "10:15:11", text: "[stderr] Warning: Deprecated API usage", stream: .stderr, ansiColor: .yellow)
        ],
        preferences: Preferences.recommendedDefaults
    )
    .frame(width: 800, height: 500)
    .padding()
}
