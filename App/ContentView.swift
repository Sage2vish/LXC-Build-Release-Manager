import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var store = RepositoryStore.shared
    @StateObject private var historyStore = BuildHistoryStore.shared
    @StateObject private var workspaceStateStore = BuildWorkspaceStateStore.shared
    @StateObject private var runners = BuildRunnerRegistry.shared
    @StateObject private var preferencesStore = PreferencesStore.shared
    @State private var isAddingRepository = false
    @Environment(\.openSettings) private var openSettings

    /// One-way: the preference decides whether the sidebar is showing, and nothing the split
    /// view reports back can change it.
    ///
    /// AppKit replays the window's saved split state during launch and pushes it through this
    /// binding. That write is indistinguishable from a real click and does not arrive at a
    /// predictable time — a delay-based guard fixed it only about half the time. Ignoring writes
    /// entirely makes the saved preference authoritative, so a sidebar hidden at quit stays
    /// hidden. SwiftUI's own sidebar toggle is removed below and replaced with a button that
    /// writes the preference, so the visible control still works.
    private var columnVisibility: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { preferencesStore.preferences.showRepositorySidebar ? .all : .detailOnly },
            set: { _ in }
        )
    }

    private func toggleSidebarPaths() {
        var updated = preferencesStore.preferences
        updated.showRepositoryPathInSidebar.toggle()
        preferencesStore.save(updated)
    }

    private func toggleSidebar() {
        var updated = preferencesStore.preferences
        updated.showRepositorySidebar.toggle()
        preferencesStore.save(updated)
    }

    private var preferredColorScheme: ColorScheme? {
        switch preferencesStore.preferences.theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    var body: some View {
        // The status bar is a sibling below the split view, not a `safeAreaInset` on it.
        // An inset does not propagate into the sidebar column's own safe area, which let the
        // status bar clip the sidebar's "Open Repository…" / "Preferences" footer.
        VStack(spacing: 0) {
            splitView
            if preferencesStore.preferences.showStatusBar {
                StatusBar(repository: store.selectedRepository, preferences: preferencesStore.preferences)
                    .background {
                        if preferencesStore.preferences.reduceTransparency {
                            Color(nsColor: .windowBackgroundColor)
                        } else {
                            ZStack {
                                Rectangle().fill(.bar)
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.13),
                                        Color.white.opacity(0.04),
                                        Color.black.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .blendMode(.softLight)
                            }
                        }
                    }
            }
        }
        .background(AppBackground(preferences: preferencesStore.preferences))
        .preferredColorScheme(preferredColorScheme)
        // Appearance preferences were stored and shown but never read; these apply them.
        .tint(AppearanceSettings.accentColor(preferencesStore.preferences))
        .environment(\.appTextScale, AppearanceSettings.textScale(preferencesStore.preferences))
        .environment(\.appRowSpacing, AppearanceSettings.rowSpacing(preferencesStore.preferences))
        .animation(
            AppearanceSettings.animation(preferencesStore.preferences),
            value: preferencesStore.preferences.showRepositorySidebar
        )
        .sheet(isPresented: $isAddingRepository) {
            AddRepositorySheet(store: store, isPresented: $isAddingRepository)
        }
        .onAppear {
            let delegate = NSApp.delegate as? AppDelegate
            delegate?.runners = runners
            delegate?.preferencesStore = preferencesStore
        }
        .task {
            // "Check for updates automatically". Deliberately fire-and-forget: a failed or slow
            // check must never delay launch or interrupt the user, so only a found update is
            // surfaced, and only in the diagnostics log plus the Preferences screen.
            guard preferencesStore.preferences.checkForUpdatesAutomatically else { return }
            let preferences = preferencesStore.preferences
            let result = await UpdateChecker.check(preferences: preferences)
            if case .updateAvailable(let update, let current) = result {
                DiagnosticsLog.write(
                    .info,
                    "Update available: \(update.version) (running \(current))",
                    preferences: preferences
                )
            }
        }
    }

    private var splitView: some View {
        navigationSplitView
            // Appearance and language live in the window's own top bar rather than in the
            // repository header: they are app-wide settings, and the header is repository
            // identity. Trailing placement, not `.principal` — the centre of the title bar sits
            // over the middle panel's content, while the right of the bar is where window-level
            // controls belong. They stay present whether or not a repository is selected.
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    AppearanceAndLanguageControls(preferencesStore: preferencesStore)
                }
            }
    }

    private var navigationSplitView: some View {
        NavigationSplitView(columnVisibility: columnVisibility) {
            sidebar
        } detail: {
            if let repository = store.selectedRepository {
                RepositoryDetailView(
                    repository: repository,
                    store: store,
                    historyStore: historyStore,
                    workspaceStateStore: workspaceStateStore,
                    preferencesStore: preferencesStore,
                    runners: runners,
                    runner: runners.runner(for: repository.id),
                    initialTab: RepositoryDetailView.DetailTab(preferencesStore.preferences.defaultLaunchTab)
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
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Label(
                        preferencesStore.preferences.showRepositorySidebar ? "Hide Sidebar" : "Show Sidebar",
                        systemImage: "sidebar.leading"
                    )
                    .labelStyle(.iconOnly)
                }
                .help(preferencesStore.preferences.showRepositorySidebar
                      ? "Hide the repository sidebar"
                      : "Show the repository sidebar")
            }
        }
    }

    /// SwiftUI's `NavigationSplitView` is backed by an `NSSplitViewController` whose split view
    /// autosaves its collapse state. Clearing the autosave name stops AppKit persisting and
    /// replaying that state, leaving the preference as the only record of what the user wanted.
    private struct SidebarRestorationDisabler: NSViewRepresentable {
        func makeNSView(context: Context) -> NSView { NSView(frame: .zero) }

        func updateNSView(_ nsView: NSView, context: Context) {
            DispatchQueue.main.async {
                var view: NSView? = nsView
                while let current = view {
                    if let splitView = current as? NSSplitView {
                        splitView.autosaveName = nil
                        return
                    }
                    view = current.superview
                }
            }
        }
    }

    private var sortedRepositories: [Repository] {
        store.repositories.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            return lhs.lastAccessed > rhs.lastAccessed
        }
    }

    private var recentRepositories: [Repository] {
        let cap = max(0, preferencesStore.preferences.maxRecentRepositories)
        return Array(store.repositories.sorted { $0.lastAccessed > $1.lastAccessed }.prefix(cap))
    }

    /// Extracted from the `sidebar` body: inline, the row plus its context menu and
    /// accessibility modifiers made the surrounding `List` too large for the type checker.
    private func repositorySidebarRow(_ repository: Repository) -> some View {
        RepositoryRow(
            repository: repository,
            store: store,
            showsPath: preferencesStore.preferences.showRepositoryPathInSidebar
        )
            .tag(repository.id)
            .contextMenu { // Screenshot UI Parity: Sidebar - Context menu actions for repository row
                Button("Reveal in Finder") {
                    guard repository.source.isLocal else { return }
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: repository.source.displayPath)])
                }
                .disabled(!repository.source.isLocal)

                Button("Open in Terminal") {
                    guard repository.source.isLocal else { return }
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                    process.arguments = ["-a", "Terminal", repository.source.displayPath]
                    try? process.run()
                }
                .disabled(!repository.source.isLocal)

                Button("Copy Path") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(repository.source.displayPath, forType: .string)
                }
            }
            // The path stays in the accessible description even when hidden visually.
            .accessibilityLabel("\(repository.name), \(repository.source.displayPath)")
            .accessibilityHint("Select repository \(repository.name)")
    }

    /// Extracted for the same reason as `repositorySidebarRow`.
    private func recentRepositorySidebarRow(_ repository: Repository) -> some View {
        // Selection is tracked by the store, not on the model.
        let isSelected = store.selectedRepositoryID == repository.id
        return HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)
            Text(repository.name)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer()
            if repository.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.yellow)
                    .accessibilityLabel("Pinned")
            }
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                    .accessibilityLabel("Selected")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { store.select(repository) }
        .contextMenu { // Screenshot UI Parity: Sidebar - Context menu for recent repository row
            Button("Reveal in Finder") {
                guard repository.source.isLocal else { return }
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: repository.source.displayPath)])
            }
            .disabled(!repository.source.isLocal)

            Button("Open in Terminal") {
                guard repository.source.isLocal else { return }
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                process.arguments = ["-a", "Terminal", repository.source.displayPath]
                try? process.run()
            }
            .disabled(!repository.source.isLocal)

            Button("Copy Path") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(repository.source.displayPath, forType: .string)
            }
        }
        .accessibilityLabel("\(repository.name), \(repository.source.displayPath), recent repository")
        .accessibilityHint("Select recent repository \(repository.name)")
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
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
                // Screenshot UI Parity: Sidebar - Repositories header with minimalistic styling
                Section {
                    ForEach(sortedRepositories) { repository in
                        repositorySidebarRow(repository)
                    }
                } header: {
                    // Screenshot UI Parity: Sidebar - Clean section header for Repositories
                    HStack(spacing: 6) {
                        Text("Repositories")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .textCase(nil)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        // The name is identity and always shows; only the path is optional.
                        Button(action: toggleSidebarPaths) {
                            Image(systemName: preferencesStore.preferences.showRepositoryPathInSidebar
                                  ? "text.alignleft"
                                  : "text.justify.left")
                        }
                        .buttonStyle(.borderless)
                        .help(preferencesStore.preferences.showRepositoryPathInSidebar
                              ? "Hide repository paths"
                              : "Show repository paths")
                        .accessibilityLabel(preferencesStore.preferences.showRepositoryPathInSidebar
                                            ? "Hide repository paths"
                                            : "Show repository paths")
                    }
                    .padding(.leading, 4)
                    .padding(.vertical, 4)
                }

                // Screenshot UI Parity: Sidebar - Recent Repositories section with header and icons for each
                if !recentRepositories.isEmpty {
                    Section {
                        ForEach(recentRepositories) { repository in
                            recentRepositorySidebarRow(repository)
                        }
                    } header: {
                        Text("Recent repositories")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .textCase(nil)
                            .padding(.leading, 4)
                            .padding(.vertical, 4)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Build Manager")
            // The single-value form pins the column and removes the drag handle.
            // min/ideal/max keeps the saved width as the starting point while letting the user drag.
            .navigationSplitViewColumnWidth(
                min: 180,
                ideal: preferencesStore.preferences.sidebarWidthPoints,
                max: 420
            )
            // Stops AppKit persisting and replaying the split view's collapse state, which
            // otherwise fights the saved preference on the next launch.
            .background(SidebarRestorationDisabler())
            // SwiftUI's built-in toggle writes through the visibility binding, which we ignore,
            // so it would look broken. The replacement lives on the split view, where it stays
            // reachable once the sidebar is hidden.
            .toolbar(removing: .sidebarToggle)

            // Screenshot UI Parity: Sidebar - Footer with separated buttons and pastel styling
            VStack(spacing: 8) {
                Divider()
                Button {
                    if let path = presentLocalFolderPickerPath() {
                        store.addLocalRepository(path: path)
                    }
                } label: {
                    Label("Open Repository…", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 34)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .help("Add a local repository folder")
                .accessibilityLabel("Open Repository")
                .accessibilityHint("Choose a local folder to add as a repository")

                Button {
                    openSettings()
                } label: {
                    Label("Preferences", systemImage: "gearshape")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 34)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Open application preferences")
                .accessibilityLabel("Preferences")
                .accessibilityHint("Open application preferences")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
            .background {
                if preferencesStore.preferences.reduceTransparency {
                    Color(nsColor: .windowBackgroundColor)
                } else {
                    ZStack {
                        Rectangle().fill(.bar)
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.06),
                                Color.black.opacity(0.03)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .blendMode(.softLight)
                    }
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
        .background {
            if preferencesStore.preferences.reduceTransparency {
                Color(nsColor: .windowBackgroundColor)
            } else {
                ZStack {
                    Rectangle().fill(AppearanceSettings.sidebarMaterial(preferencesStore.preferences))
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            Color.white.opacity(0.08),
                            Color.black.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .blendMode(.softLight)
                }
            }
        }
    }
}
