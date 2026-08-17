import SwiftUI
import AppKit

struct PreferencesView: View {
    @ObservedObject var store: PreferencesStore
    @ObservedObject var historyStore: BuildHistoryStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Preferences
    @State private var selectedTab: PrefTab = .general
    @State private var pendingClearHistoryConfirmation = false
    @State private var isCheckingForUpdates = false
    @State private var updateStatus: String?
    @State private var availableUpdateURL: URL?

    init(store: PreferencesStore, historyStore: BuildHistoryStore) {
        self.store = store
        self.historyStore = historyStore
        self._draft = State(initialValue: store.preferences)
    }

    enum PrefTab: String, CaseIterable, Identifiable {
        case general = "General"
        case repositories = "Repositories"
        case buildExecution = "Build Execution"
        case logsConsole = "Logs & Console"
        case appearance = "Appearance"
        case notifications = "Notifications"
        case advanced = "Advanced"
        var id: String { rawValue }

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .repositories: return "folder"
            case .buildExecution: return "chevron.left.forwardslash.chevron.right"
            case .logsConsole: return "doc.plaintext"
            case .appearance: return "paintbrush"
            case .notifications: return "bell"
            case .advanced: return "slider.horizontal.3"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Preferences")
                .font(.headline)
                .padding(.vertical, 12)
            Divider()

            HStack(spacing: 0) {
                List(PrefTab.allCases, selection: $selectedTab) { tab in
                    Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                }
                .listStyle(.sidebar)
                .frame(width: 190)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        tabContent
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            Divider()

            HStack {
                Button("Restore Defaults") { draft = .recommendedDefaults }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    store.save(draft)
                    applyLanguageIfChanged()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
        .frame(width: 760, height: 580)
        .onAppear {
            draft = store.preferences
        }
        .onChange(of: store.preferences) { _, newValue in
            draft = newValue
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .general: generalTab
        case .repositories: repositoriesTab
        case .buildExecution: buildExecutionTab
        case .logsConsole: logsConsoleTab
        case .appearance: appearanceTab
        case .notifications: notificationsTab
        case .advanced: advancedTab
        }
    }

    private var updateStatusText: String {
        if let updateStatus { return updateStatus }
        let current = UpdateChecker.currentVersion().map(\.description) ?? "unknown"
        return "Current version \(current). Checking uses GitHub Releases."
    }

    /// Runs the check the "Check for updates automatically" preference would run at launch,
    /// using the channel currently selected in this draft.
    private func checkForUpdatesNow() async {
        isCheckingForUpdates = true
        availableUpdateURL = nil
        defer { isCheckingForUpdates = false }

        switch await UpdateChecker.check(preferences: draft) {
        case .upToDate(let current):
            updateStatus = "Up to date — running \(current)."
        case .updateAvailable(let update, let current):
            updateStatus = "Update available: \(update.version) (running \(current))."
            availableUpdateURL = update.releaseURL
        case .failed(let reason):
            updateStatus = reason
        }
    }

    /// Applies the language override and offers a relaunch, because macOS only picks up
    /// `AppleLanguages` on the next launch.
    private func applyLanguageIfChanged() {
        let language = AppLanguage(preference: draft.language)
        guard AppLanguageController.apply(language) else { return }

        let alert = NSAlert()
        alert.messageText = "Relaunch to change language?"
        alert.informativeText = "Build Manager applies the language when it next starts."
        alert.addButton(withTitle: "Relaunch Now")
        alert.addButton(withTitle: "Later")
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let url = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, _ in
            Task { @MainActor in NSApp.terminate(nil) }
        }
    }

    // MARK: 01 General

    private var generalTab: some View {
        Group {
            tabHeader("General", "Overall application behaviour.")
            toggleRow("Launch Build Manager at login", "Automatically start the application when you log in to macOS.", $draft.launchAtLogin)
            toggleRow("Restore last opened repository on launch", "Open the last repository you were working with.", $draft.restoreLastOpenedRepository)
            pickerRow("Default tab on launch", "Select which tab to show when Build Manager starts.") {
                Picker("", selection: $draft.defaultLaunchTab) {
                    ForEach(DefaultLaunchTab.allCases) { Text($0.rawValue).tag($0) }
                }
                .labelsHidden()
                .frame(width: 160)
            }
            toggleRow("Remember recent repositories", "Store recently opened repositories for quick access.", $draft.rememberRecentRepositories)
            stepperRow("Maximum recent repositories", "Number of repositories to keep in the Recent list.", $draft.maxRecentRepositories, range: 1...50)
            toggleRow("Confirm before quitting while a build is running", "Prevent accidental quit when a build process is active.", $draft.confirmBeforeQuittingDuringBuild)
            toggleRow("Confirm before clearing history or logs", "Ask for confirmation before clearing history or deleting logs.", $draft.confirmBeforeClearing)
            toggleRow("Check for updates automatically", "Check GitHub Releases for a newer version when Build Manager starts.", $draft.checkForUpdatesAutomatically)
            pickerRow("Update channel", "Stable skips prereleases. Beta includes them.") {
                Picker("", selection: $draft.updateChannel) {
                    Text("Stable (Recommended)").tag("Stable (Recommended)")
                    Text("Beta").tag("Beta")
                }
                .labelsHidden()
                .frame(width: 200)
            }
            pickerRow("Updates", updateStatusText) {
                Button(isCheckingForUpdates ? "Checking…" : "Check Now") {
                    Task { await checkForUpdatesNow() }
                }
                .disabled(isCheckingForUpdates)
            }
            if let url = availableUpdateURL {
                Link("Open the release page", destination: url)
                    .font(.callout)
                    .padding(.leading, 4)
            }
            pickerRow("Language", "English is the main language. Changing this needs a relaunch.") {
                Picker("", selection: $draft.language) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.nativeName).tag(language.rawValue)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
            }
        }
    }

    // MARK: 02 Repositories

    private var repositoriesTab: some View {
        Group {
            tabHeader("Repositories", "Configure how repositories are discovered, scanned, and remembered.")
            toggleRow("Default repository root detection", "When opening a folder, automatically look for a /build directory.", $draft.defaultRepositoryRootDetection)
            textFieldRow("Default /build folder name", "Folder name that contains scripts, logs, and project config.", $draft.defaultBuildFolderName)
            textFieldRow("Scripts directory (inside /build)", "Relative path where build scripts are located.", $draft.scriptsSubdirectory)
            textFieldRow("Logs directory (inside /build)", "Relative path where build logs are stored.", $draft.logsSubdirectory)
            toggleRow("Scan subdirectories for /build folders", "Also detect /build in subfolders when opening a repository.", $draft.scanSubdirectoriesForBuild)
            stepperRow("Maximum number of Recent Repositories", "Limit how many repositories are kept in the Recent list.", $draft.maxRecentRepositories, range: 1...50)
            toggleRow("Automatically restore last opened repositories", "Re-open the repositories that were open in the previous session.", $draft.automaticallyRestoreLastOpenedRepositories)
            pickerRow("GitHub access (optional)", "Used to fetch private repositories and metadata.") {
                SecureField("Personal access token", text: $draft.gitHubToken)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            }
            toggleRow("Auto-detect repositories on startup", "Check default locations for repositories when app launches.", $draft.autoDetectRepositoriesOnStartup)
        }
    }

    // MARK: 03 Build Execution

    private var buildExecutionTab: some View {
        Group {
            tabHeader("Build Execution", "Configure how build scripts are executed.")
            pickerRow("Default shell", "Shell used to run build scripts.") {
                Picker("", selection: $draft.defaultShell) {
                    Text("/bin/zsh").tag("/bin/zsh")
                    Text("/bin/bash").tag("/bin/bash")
                    Text("/bin/sh").tag("/bin/sh")
                }
                .labelsHidden()
                .frame(width: 140)
            }
            pickerRow("Working directory", "Directory where scripts are executed.") {
                Picker("", selection: $draft.workingDirectoryChoice) {
                    Text("Repository Root").tag("Repository Root")
                    Text("Custom").tag("Custom")
                }
                .labelsHidden()
                .frame(width: 160)
            }
            pickerRow("Environment variables", "Set default environment variables for all builds.") {
                Text("\(draft.environmentVariables.count) defined").foregroundStyle(.secondary)
            }
            stepperRow("Max concurrent builds", "Maximum number of builds that can run at the same time.", $draft.maxConcurrentBuilds, range: 1...10)
            stepperRow("Build timeout (min, 0 = no limit)", "Maximum time allowed for a single build to run.", $draft.buildTimeoutMinutes, range: 0...600)
            toggleRow("Terminate child processes on Stop", "Kill all child processes when a build is stopped.", $draft.terminateChildProcessesOnStop)
            toggleRow("Preserve partial output on cancellation", "Keep output generated before a build is cancelled.", $draft.preservePartialOutputOnCancellation)
            toggleRow("Automatically save logs", "Save log file after a build completes.", $draft.automaticallySaveLogs)
            toggleRow("Prevent macOS sleep while a build is running", "Keep system awake during long running builds.", $draft.preventSleepDuringBuild)
            pickerRow("Default behavior after build completes", "What to do when a build finishes.") {
                Picker("", selection: $draft.defaultBehaviorAfterBuildCompletes) {
                    Text("Stay on Output").tag("Stay on Output")
                    Text("Switch to History").tag("Switch to History")
                }
                .labelsHidden()
                .frame(width: 160)
            }
        }
    }

    // MARK: 04 Logs & Console

    private var logsConsoleTab: some View {
        Group {
            tabHeader("Logs & Console", "Configure how logs are stored and displayed.")
            toggleRow("Save build logs to disk automatically", "Every build run will be saved to a log file.", $draft.saveLogsAutomatically)
            pickerRow("Log retention period", "Automatically delete logs older than the selected period.") {
                Stepper("\(draft.logRetentionDays) days", value: $draft.logRetentionDays, in: 1...365)
            }
            pickerRow("Maximum log file size", "Rotate/create a new log when size limit is reached.") {
                Stepper("\(draft.maxLogFileSizeMB) MB", value: $draft.maxLogFileSizeMB, in: 1...1000)
            }
            stepperRow("Maximum number of stored logs", "Oldest logs will be removed when limit is exceeded.", $draft.maxStoredLogs, range: 1...1000)
            pickerRow("Timestamp format", "Format used for timestamps in logs and console.") {
                Picker("", selection: $draft.timestampFormat) {
                    Text("[HH:mm:ss]").tag("[HH:mm:ss]")
                    Text("HH:mm:ss").tag("HH:mm:ss")
                }
                .labelsHidden()
                .frame(width: 140)
            }
            pickerRow("Encoding", "Character encoding for log files.") {
                Picker("", selection: $draft.logEncoding) {
                    Text("UTF-8").tag("UTF-8")
                    Text("System").tag("System")
                }
                .labelsHidden()
                .frame(width: 120)
            }
            pickerRow("Console font", "Font used in the live output and log viewer.") {
                Text(draft.consoleFontName).foregroundStyle(.secondary)
            }
            stepperRow("Font size", "Adjust the font size for console text.", $draft.consoleFontSize, range: 9...24)
            pickerRow("Line spacing", "Space between lines in the console.") {
                Stepper(String(format: "%.1f", draft.lineSpacing), value: $draft.lineSpacing, in: 1.0...2.0, step: 0.1)
            }
            toggleRow("Word wrap", "Wrap long lines in the console and log viewer.", $draft.wordWrap)
            toggleRow("Auto-scroll to bottom", "Automatically scroll to the latest output.", $draft.autoScrollToBottom)
            toggleRow("Show line numbers", "Show line numbers in log viewer.", $draft.showLineNumbers)
            toggleRow("Colorize output", "Highlight INFO / WARN / ERROR / SUCCESS.", $draft.colorizeOutput)
            pickerRow("Default log filter", "Applied when opening a log.") {
                Picker("", selection: $draft.defaultLogFilter) {
                    Text("All Lines").tag("All Lines")
                    Text("Errors").tag("Errors")
                    Text("Warnings").tag("Warnings")
                    Text("Info").tag("Info")
                }
                .labelsHidden()
                .frame(width: 130)
            }
            toggleRow("Search is case sensitive", "Case sensitive search in logs.", $draft.searchIsCaseSensitive)
        }
    }

    // MARK: 05 Appearance

    private var appearanceTab: some View {
        Group {
            tabHeader("Appearance", "Customize the look and feel of Build Manager.")
            pickerRow("Theme", "Light, dark, or match the system appearance.") {
                Picker("", selection: $draft.theme) {
                    ForEach(AppTheme.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)
            }
            pickerRow("UI Density", "Adjust the spacing and size of elements in the app.") {
                Picker("", selection: $draft.uiDensity) {
                    Text("Comfortable").tag("Comfortable")
                    Text("Compact").tag("Compact")
                }
                .labelsHidden()
                .frame(width: 160)
            }
            pickerRow("Sidebar Width", "Choose the width of the left sidebar.") {
                Picker("", selection: $draft.sidebarWidth) {
                    Text("Narrow (220px)").tag("Narrow (220px)")
                    Text("Medium (280px)").tag("Medium (280px)")
                    Text("Wide (340px)").tag("Wide (340px)")
                }
                .labelsHidden()
                .frame(width: 160)
            }
            stepperRow("Text Size (%)", "Adjust the base text size in the app.", $draft.textSizePercent, range: 80...150)
            toggleRow("Show animations", "Enable subtle animations for a smoother experience.", $draft.showAnimations)
            toggleRow("Round window corners", "Use rounded corners for windows and panels.", $draft.roundWindowCorners)
            toggleRow("Reduce transparency", "Minimize transparency effects for better readability.", $draft.reduceTransparency)
            toggleRow("Use system font (San Francisco)", "Use macOS system font for a native look.", $draft.useSystemFont)
        }
    }

    // MARK: 06 Notifications

    private var notificationsTab: some View {
        Group {
            tabHeader("Notifications", "Configure how and when you want to be notified about builds.")
            toggleRow("Enable build notifications", "Show notifications for build events.", $draft.enableBuildNotifications)
            toggleRow("Build Started", "Notify when a build starts.", $draft.notifyBuildStarted)
            toggleRow("Build Succeeded", "Notify when a build completes successfully.", $draft.notifyBuildSucceeded)
            toggleRow("Build Failed", "Notify when a build fails.", $draft.notifyBuildFailed)
            toggleRow("Build Cancelled / Stopped", "Notify when a build is cancelled or stopped.", $draft.notifyBuildCancelled)
            toggleRow("Long Running Build Completed", "Notify when a long running build finishes.", $draft.notifyLongRunningBuildCompleted)
            toggleRow("Notify only when Build Manager is not in focus", "Avoid interrupting you while you're already in the app.", $draft.notifyOnlyWhenNotInFocus)
            pickerRow("Play sound", "Play a system sound with notifications.") {
                Picker("", selection: $draft.notificationSound) {
                    Text("Glass").tag("Glass")
                    Text("Ping").tag("Ping")
                    Text("None").tag("None")
                }
                .labelsHidden()
                .frame(width: 120)
            }
            pickerRow("Show notification duration", "How long notifications stay visible.") {
                Picker("", selection: $draft.notificationDuration) {
                    Text("5 seconds").tag("5 seconds")
                    Text("10 seconds").tag("10 seconds")
                }
                .labelsHidden()
                .frame(width: 130)
            }
            toggleRow("Group multiple notifications", "Combine multiple events into a single notification.", $draft.groupMultipleNotifications)
        }
    }

    // MARK: 07 Advanced

    private var advancedTab: some View {
        Group {
            tabHeader("Advanced", "Advanced and diagnostic options for power users.")
            toggleRow("Allow scripts outside /build/scripts", "Allow executing scripts from anywhere in the repository.", $draft.allowScriptsOutsideBuildScripts)
            stepperRow("Custom build timeout (overrides per-build timeout, 0 = none)", "Set a global timeout for all builds.", $draft.globalBuildTimeoutMinutes, range: 0...600)
            toggleRow("Detect executable files automatically", "Treat files with exec permission as runnable scripts.", $draft.detectExecutableFilesAutomatically)
            toggleRow("Terminate process tree on Stop", "Kill all child processes and their children when build is stopped.", $draft.terminateChildProcessesOnStop)
            toggleRow("Verbose / Debug logging", "Enable detailed internal logging for troubleshooting.", $draft.verboseDebugLogging)
            toggleRow("Log internal diagnostics to file", "Save Build Manager diagnostics to disk.", $draft.logInternalDiagnosticsToFile)
            textFieldRow("Diagnostics log location", "Location where diagnostic logs are stored.", $draft.diagnosticsLogLocation)
            pickerRow("GitHub rate limit alerts", "Warn when API rate limit is low.") {
                Picker("", selection: $draft.gitHubRateLimitAlertThreshold) {
                    Text("Warn me at 20%").tag("Warn me at 20%")
                    Text("Warn me at 10%").tag("Warn me at 10%")
                    Text("Never").tag("Never")
                }
                .labelsHidden()
                .frame(width: 150)
            }

            Divider().padding(.vertical, 4)

            Text("Data & Maintenance").font(.callout.weight(.semibold))
            dataMaintenanceRow("Open Build Manager data directory", "Open the folder where Build Manager stores its data.", "Open Folder") {
                NSWorkspace.shared.open(AppDataLocations.supportDirectory())
            }
            dataMaintenanceRow("Open projects.json", "Open the projects.json config template in your default editor.", "Open File") {
                openProjectsJSONTemplate()
            }
            dataMaintenanceRow("Clear repository metadata cache", "No metadata cache exists yet — every scan is already live, so this is a no-op today.", "Clear Cache") {}
                .disabled(true)
            dataMaintenanceRow("Clear build history", "Remove all build history from this machine.", "Clear History") {
                if draft.confirmBeforeClearing {
                    pendingClearHistoryConfirmation = true
                } else {
                    historyStore.clearAll()
                }
            }
            dataMaintenanceRow("Reset all warnings", "No \"Don't show again\" warning system exists yet — this is a no-op today.", "Reset Warnings") {}
                .disabled(true)

            Divider().padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                Text("⚠️ Danger Zone").font(.callout.weight(.semibold)).foregroundStyle(.red)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Restore All Defaults")
                        Text("Reset all preferences to default values.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Restore Defaults…", role: .destructive) {
                        draft = .recommendedDefaults
                    }
                }
            }
            .padding(12)
            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
        .alert("Clear Build History?", isPresented: $pendingClearHistoryConfirmation) {
            Button("Clear History", role: .destructive) { historyStore.clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all recorded build history from this machine. Log files on disk are not deleted.")
        }
    }

    private func openProjectsJSONTemplate() {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // App/
            .deletingLastPathComponent() // LXC-BRM/
            .appendingPathComponent("Support/build-release/projects.json")
        NSWorkspace.shared.open(repoRoot)
    }

    private func dataMaintenanceRow(_ title: String, _ subtitle: String, _ buttonTitle: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            Button(buttonTitle, action: action)
        }
    }

    // MARK: Row helpers

    private func tabHeader(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.title2.weight(.semibold))
            Text(subtitle).font(.callout).foregroundStyle(.secondary)
        }
        .padding(.bottom, 6)
    }

    private func toggleRow(_ title: String, _ subtitle: String, _ isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func stepperRow(_ title: String, _ subtitle: String, _ value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        pickerRow(title, subtitle) {
            Stepper("\(value.wrappedValue)", value: value, in: range)
                .frame(width: 100)
        }
    }

    private func textFieldRow(_ title: String, _ subtitle: String, _ text: Binding<String>) -> some View {
        pickerRow(title, subtitle) {
            TextField("", text: text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
        }
    }

    private func pickerRow<Content: View>(_ title: String, _ subtitle: String, @ViewBuilder control: () -> Content) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 12)
            control()
        }
    }
}
#Preview {
    PreferencesView(
        store: PreferencesStore.shared,
        historyStore: BuildHistoryStore.shared
    )
}

