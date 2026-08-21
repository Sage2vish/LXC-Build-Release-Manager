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

    /// The height of the window's title bar, measured once from the window itself.
    ///
    /// The app draws that strip now, so it has to know how tall macOS made it: the height changes
    /// with the toolbar style and with the system's own settings, and a guessed number leaves
    /// either a seam above the content or a band the toolbar buttons hang out of.
    @State private var titleBarHeight: CGFloat = 0

    /// Where the right panel starts, as a distance from the window's right edge — and therefore
    /// where the top bar and the status strip both have to stop. Zero when the panel is hidden,
    /// which is the shell's own preference rather than anything the panel reports.
    private var detailPanelInset: CGFloat {
        guard preferencesStore.preferences.showDetailInspector, store.selectedRepository != nil else { return 0 }
        return detailPanelWidth
    }

    /// How much of the bottom of a column the status strip covers, and therefore how much that
    /// column has to keep clear. Zero when the strip is hidden, so hiding it hands the space back.
    private var statusBarInset: CGFloat {
        preferencesStore.preferences.showStatusBar ? LayoutMetrics.statusBarHeight : 0
    }

    private var preferredColorScheme: ColorScheme? {
        switch preferencesStore.preferences.theme {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    /// The live width of the right panel, measured by the panel itself.
    ///
    /// The status strip needs it: the strip runs from the window's left edge and stops where the
    /// panel begins, exactly like the title bar above it. The panel is draggable, so the number
    /// cannot be a constant — it is reported back on every layout, and is `0` whenever the panel
    /// is hidden or no repository is open.
    @State private var detailPanelWidth: CGFloat = 0

    var body: some View {
        // The strip lies **over** the bottom of the window rather than being stacked beneath it.
        //
        // Stacked, it cut every column short — including the right panel, which then ended on a
        // shelf instead of running the height of the window the way a macOS sidebar does. Laid
        // over the bottom and stopped at the panel's leading edge, the panel runs top to bottom in
        // one straight line and the strip spans the same width the title bar spans above it.
        //
        // The sidebar and the centre column each reserve the strip's height in their own safe
        // area. An inset on the split view itself does not reach the sidebar column — that is what
        // clipped the sidebar's "Open Repository…" / "Preferences" footer the last time this was
        // tried.
        splitView
        .overlay(alignment: .bottomLeading) {
            if preferencesStore.preferences.showStatusBar {
                StatusBar(
                    repository: store.selectedRepository,
                    preferences: preferencesStore.preferences
                )
                .padding(.trailing, detailPanelInset)
            }
        }
        // The strip level with the title bar, painted by the app rather than by the toolbar.
        //
        // macOS draws the toolbar's own background across the whole window and nothing can make it
        // stop short of a column, so it is hidden and this takes its place: glass over the sidebar
        // and the centre, the right panel's own surface over the panel. That is what makes the
        // panel read as one column from the top of the window to the bottom, with the top bar
        // ending at its edge — the same rule the status strip follows along the bottom.
        //
        // It is painted from the background layer, which already sits outside the safe area. A
        // view that reaches *up* into the safe area from inside the content feeds its own layout
        // back into the window's, and the two never settle.
        .background(
            WindowTopChrome(
                height: titleBarHeight,
                panelWidth: detailPanelInset,
                reduceTransparency: preferencesStore.preferences.reduceTransparency
            )
        )
        .background(WindowChrome(titleBarHeight: $titleBarHeight))
        .modifier(LanguageChangeHandler(pending: $pendingLanguageRelaunch))
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

    /// The window width captured at first layout, used only to seed the two side columns.
    ///
    /// Deliberately not updated as the window resizes: a live ideal re-pins the columns and makes
    /// them impossible to drag. The clamps below still follow the live width.
    @State private var seedWidth: CGFloat?
    /// Set when a language switch actually changed the override and a relaunch is needed.
    @State private var pendingLanguageRelaunch: AppLanguage?

    private var splitView: some View {
        // One measurement of the window, shared by both side columns, so their widths are
        // proportions of what is actually on screen rather than fixed point values that mean
        // something different on every display.
        GeometryReader { proxy in
            splitViewContent(windowWidth: proxy.size.width)
                .onAppear {
                    if seedWidth == nil, proxy.size.width > 0 { seedWidth = proxy.size.width }
                }
        }
    }

    private func splitViewContent(windowWidth: CGFloat) -> some View {
        navigationSplitView(windowWidth: windowWidth)
            // Appearance and language live in the window's own top bar rather than in the
            // repository header: they are app-wide settings, and the header is repository
            // identity. Trailing placement, not `.principal` — the centre of the title bar sits
            // over the middle panel's content, while the right of the bar is where window-level
            // controls belong. They stay present whether or not a repository is selected.
            .toolbar {
                // Two items, not one group: they are separate controls and macOS gives them its
                // own spacing, rather than being glued together inside a single item.
                ToolbarItem(placement: .primaryAction) {
                    AppearanceSlider(theme: preferencesStore.binding(\.theme))
                }
                ToolbarItem(placement: .primaryAction) {
                    LanguagePicker(
                        language: preferencesStore.binding(\.language),
                        onChangeRequiresRelaunch: { language in
                            if AppLanguageController.apply(language) { pendingLanguageRelaunch = language }
                        }
                    )
                }
            }
    }

    private func navigationSplitView(windowWidth: CGFloat) -> some View {
        NavigationSplitView(columnVisibility: columnVisibility) {
            sidebar(windowWidth: windowWidth)
        } detail: {
            if let repository = store.selectedRepository {
                RepositoryDetailView(
                    windowWidth: windowWidth,
                    seedWidth: seedWidth ?? windowWidth,
                    repository: repository,
                    store: store,
                    historyStore: historyStore,
                    workspaceStateStore: workspaceStateStore,
                    preferencesStore: preferencesStore,
                    runners: runners,
                    runner: runners.runner(for: repository.id),
                    initialTab: RepositoryDetailView.DetailTab(preferencesStore.preferences.defaultLaunchTab),
                    panelWidth: $detailPanelWidth
                )
                .id(repository.id)
            } else {
                ContentUnavailableView(
                    "Select a Repository",
                    systemImage: "shippingbox",
                    description: Text("Choose a repository from the sidebar, or add one to begin.")
                )
                .background(.background)
                // No repository, no right panel — so the strip runs the full width of the window.
                .onAppear { detailPanelWidth = 0 }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    Color.clear.frame(height: statusBarInset)
                }
            }
        }
        // The app draws the top band itself; macOS's own toolbar background cannot be told to
        // stop at the panel, so it is hidden and the band takes its place.
        .toolbarBackground(.hidden, for: .windowToolbar)
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
    /// Stops AppKit restoring an old sidebar width, and sets the proportional one instead.
    ///
    /// `navigationSplitViewColumnWidth(ideal:)` only decides the width when AppKit has no opinion.
    /// It had one: `NSSplitView` persists its divider position under an autosave name, so every
    /// launch replayed whatever width the column happened to have months ago — which is why the
    /// sidebar came back at roughly 8% of the window however clearly 20% was specified.
    ///
    /// This clears the autosave, deletes the stored frames, and sets the divider once per launch.
    /// Once. After that the drag is the user's, and nothing snaps back.
    /// Turns the title bar into a transparent strip over the window instead of a band drawn across
    /// the top of it.
    ///
    /// With the bar transparent, whatever sits under it shows through — which is how the right
    /// panel reaches the top of the window and reads as one column from the top edge to the
    /// bottom, the way a full-height sidebar does in any macOS app. The band the user still sees
    /// over the sidebar and the centre is drawn by `WindowTopChrome`, which is what lets it stop at
    /// the panel's edge.
    ///
    /// Applied once. Touching the title bar invalidates the window's layout, and a change made on
    /// every pass invalidates it again from inside the pass it caused — the app then spins at 100%
    /// CPU and never shows a window at all.
    private struct WindowChrome: NSViewRepresentable {
        @Binding var titleBarHeight: CGFloat

        /// A view that says when it has a window.
        ///
        /// `updateNSView` is the wrong place to ask: on the first pass the view is not in a window
        /// yet, and SwiftUI has no reason to call it again just because one arrived. AppKit does
        /// say so, exactly once, and that is the moment the window can be read and changed.
        final class ProbeView: NSView {
            var onWindow: ((NSWindow) -> Void)?

            override func viewDidMoveToWindow() {
                super.viewDidMoveToWindow()
                guard let window else { return }
                // Deferred: at this moment the window is mid-layout and reports the frame it had
                // before this pass. A turn later it reports the one it has.
                DispatchQueue.main.async { [weak window] in
                    guard let window else { return }
                    self.onWindow?(window)
                }
            }
        }

        func makeNSView(context: Context) -> NSView {
            let view = ProbeView(frame: .zero)
            view.onWindow = { window in
                window.titlebarAppearsTransparent = true
                // The strip macOS reserves for the title bar and toolbar together, which is
                // exactly the strip the app now draws. Anything absurd is ignored rather than
                // painted.
                let measured = window.frame.height - window.contentLayoutRect.height
                guard measured > 0, measured < 200 else { return }
                titleBarHeight = measured
            }
            return view
        }

        func updateNSView(_ nsView: NSView, context: Context) {}

    }

    private struct SidebarWidthEnforcer: NSViewRepresentable {
        let targetWidth: CGFloat

        final class Coordinator {
            var applied = false
        }

        func makeCoordinator() -> Coordinator { Coordinator() }
        func makeNSView(context: Context) -> NSView { NSView(frame: .zero) }

        func updateNSView(_ nsView: NSView, context: Context) {
            guard !context.coordinator.applied, targetWidth > 0 else { return }
            DispatchQueue.main.async {
                var view: NSView? = nsView
                while let current = view {
                    guard let splitView = current as? NSSplitView else {
                        view = current.superview
                        continue
                    }
                    Self.forgetStoredFrames(named: splitView.autosaveName)
                    splitView.autosaveName = nil
                    guard splitView.arrangedSubviews.count > 1 else { return }
                    splitView.setPosition(targetWidth, ofDividerAt: 0)
                    context.coordinator.applied = true
                    return
                }
            }
        }

        /// AppKit writes divider positions into user defaults; leaving them behind means the old
        /// width returns the moment this enforcement is removed.
        private static func forgetStoredFrames(named autosaveName: NSSplitView.AutosaveName?) {
            let defaults = UserDefaults.standard
            var keys = ["NSSplitView Subview Frames \(autosaveName ?? "")"]
            keys += defaults.dictionaryRepresentation().keys.filter {
                $0.hasPrefix("NSSplitView Subview Frames")
            }
            for key in Set(keys) { defaults.removeObject(forKey: key) }
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

    /// Which piece of the surrounding box a row is responsible for, and whether it is the selected
    /// one. Looked up rather than zipped in, so the rows keep the identity the list already knows
    /// them by — pairing each row with an index changes that identity, and two sections listing the
    /// same repositories then draw each other's rows.
    private func boxBackground(for repository: Repository, in group: [Repository]) -> ListBoxRowBackground {
        let index = group.firstIndex(of: repository) ?? 0
        return ListBoxRowBackground(
            position: .init(index: index, count: group.count),
            isSelected: store.selectedRepositoryID == repository.id
        )
    }

    /// Extracted from the `sidebar` body: inline, the row plus its context menu and
    /// accessibility modifiers made the surrounding `List` too large for the type checker.
    private func repositorySidebarRow(_ repository: Repository) -> some View {
        RepositoryRow(
            repository: repository,
            store: store,
            showsPath: preferencesStore.preferences.showRepositoryPathInSidebar
        )
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            .listRowSeparator(.hidden)
            .contentShape(Rectangle())
            .onTapGesture { store.select(repository) }
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
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
        .listRowSeparator(.hidden)
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

    private func sidebar(windowWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            // No selection binding: the list's own highlight is a full-width bar that cuts
            // straight through the box the rows are drawn in. Selection is a tap on the row and a
            // tint inside the box instead, which is what the recents rows already did.
            List {
                // Screenshot UI Parity: Sidebar - Repositories header with minimalistic styling
                Section {
                    // One box around the whole list, not one per row: the rows are separated by
                    // hairlines inside it, and the box's own outline is drawn by its end rows.
                    ForEach(sortedRepositories) { repository in
                        repositorySidebarRow(repository)
                            .listRowBackground(boxBackground(for: repository, in: sortedRepositories))
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
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                }

                // Screenshot UI Parity: Sidebar - Recent Repositories section with header and icons for each
                if !recentRepositories.isEmpty {
                    Section {
                        // Identified by position, not by repository: these are the same
                        // repositories the section above lists, and two rows in one list carrying
                        // the same identity end up drawing each other's contents.
                        ForEach(Array(recentRepositories.enumerated()), id: \.offset) { index, repository in
                            recentRepositorySidebarRow(repository)
                                .listRowBackground(
                                    ListBoxRowBackground(
                                        position: .init(index: index, count: recentRepositories.count),
                                        isSelected: store.selectedRepositoryID == repository.id
                                    )
                                )
                        }
                    } header: {
                        Text("Recent repositories")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .textCase(nil)
                            .padding(.leading, 4)
                            .padding(.top, 10)
                            .padding(.bottom, 6)
                            .accessibilityAddTraits(.isHeader)
                    }
                }
            }
            // Plain, not `.sidebar`: the sidebar style insets and rounds every row on its own,
            // which fights a box drawn around the whole group. The panel's glass is its
            // background, so the list brings none of its own.
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .navigationTitle("Build Manager")
            // The single-value form pins the column and removes the drag handle. min/ideal/max
            // keeps it draggable, and every number is a fraction of the window from
            // `LayoutMetrics` — the sidebar starts at 20%.
            .navigationSplitViewColumnWidth(
                min: LayoutMetrics.sidebarColumn(for: windowWidth).min,
                // Seeded once. A live ideal would drag the column back under the pointer.
                ideal: LayoutMetrics.sidebarColumn(for: seedWidth ?? windowWidth).ideal,
                max: LayoutMetrics.sidebarColumn(for: windowWidth).max
            )
            // Clears the divider position AppKit restored from an earlier session and applies
            // the proportional width once, so 20% is what actually appears.
            .background(
                SidebarWidthEnforcer(
                    targetWidth: LayoutMetrics.sidebarColumn(for: seedWidth ?? windowWidth).ideal
                )
            )
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
        // The strip is drawn over the window, so the column has to keep its own hands clear of
        // it: the reserved band keeps the footer buttons above the glass while the sidebar's
        // material still runs all the way down behind it.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: statusBarInset)
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
