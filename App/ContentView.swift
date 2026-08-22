import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var store = RepositoryStore.shared
    @StateObject private var historyStore = BuildHistoryStore.shared
    @StateObject private var workspaceStateStore = BuildWorkspaceStateStore.shared
    @StateObject private var runners = BuildRunnerRegistry.shared
    @StateObject private var preferencesStore = PreferencesStore.shared
    @StateObject private var identityScanStore = RepositoryIdentityScanStore.shared
    @State private var isAddingRepository = false
    @State private var isIdentityScanPromptPresented = false
    @State private var pendingIdentityScanRepository: Repository?
    @State private var identityScanRepository: Repository?
    @State private var forceIdentityRescan = false

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

    private func toggleSidebar() {
        var updated = preferencesStore.preferences
        updated.showRepositorySidebar.toggle()
        preferencesStore.save(updated)
    }

    /// The live width of the left sidebar, measured by the sidebar itself.
    ///
    /// The two bands begin where it ends, so a dragged sidebar moves both. Same rules as the right
    /// panel's width: whole points, never a transient zero, or the report and the layout it causes
    /// chase each other forever.
    @State private var sidebarWidth: CGFloat = 0

    /// The height of the window's title bar, measured once from the window itself.
    ///
    /// The app draws that strip now, so it has to know how tall macOS made it: the height changes
    /// with the toolbar style and with the system's own settings, and a guessed number leaves
    /// either a seam above the content or a band the toolbar buttons hang out of.
    @State private var titleBarHeight: CGFloat = 0

    /// Where the sidebar ends, and therefore where the top bar and the status strip begin. Zero
    /// when the sidebar is hidden, which is the shell's own preference rather than anything the
    /// sidebar reports.
    private var sidebarInset: CGFloat {
        preferencesStore.preferences.showRepositorySidebar ? sidebarWidth : 0
    }

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
        // The strip belongs to the middle column, and is laid **over** the bottom of it rather
        // than stacked beneath everything.
        //
        // Stacked, it cut all three columns short, and the two side columns ended on a shelf
        // instead of running the height of the window the way a Mac window's columns do. It now
        // begins where the sidebar ends and stops where the right panel begins — the same span the
        // bar above it has — and both side columns run past it to the window's bottom edge.
        //
        // Only the centre column reserves the strip's height, in its own safe area. An inset on the
        // split view itself does not reach the sidebar column, which is what clipped the sidebar's
        // "Open Repository…" / "Preferences" footer the last time this was tried.
        splitView
        .overlay(alignment: .bottomLeading) {
            if preferencesStore.preferences.showStatusBar {
                StatusBar(
                    repository: store.selectedRepository,
                    preferences: preferencesStore.preferences
                )
                // The same vertical edge the top bar has where it meets the sidebar. Without it
                // the strip runs into the column and the two bars stop matching.
                .overlay(alignment: .leading) {
                    if sidebarInset > 0 {
                        Rectangle()
                            .fill(Color(nsColor: .separatorColor))
                            .frame(width: 1)
                            .opacity(preferencesStore.preferences.reduceTransparency ? 0.8 : 1)
                    }
                }
                .padding(.leading, sidebarInset)
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
                sidebarWidth: sidebarInset,
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
        .alert("Scan Repository?", isPresented: $isIdentityScanPromptPresented) {
            Button("Skip", role: .cancel) {
                pendingIdentityScanRepository = nil
            }
            Button("Scan Now") {
                let repository = pendingIdentityScanRepository
                pendingIdentityScanRepository = nil
                forceIdentityRescan = false
                DispatchQueue.main.async {
                    identityScanRepository = repository
                }
            }
        } message: {
            Text("Self-identify build scripts, saved logs, and Markdown documents before opening the workspace.")
        }
        .sheet(item: $identityScanRepository) { repository in
            RepositoryIdentityScanSheet(
                repository: repository,
                preferences: preferencesStore.preferences,
                additionalScriptPaths: workspaceStateStore.state(for: repository.id).addedScriptPaths,
                forceRescan: forceIdentityRescan,
                scanStore: identityScanStore,
                onClose: {
                    identityScanRepository = nil
                    forceIdentityRescan = false
                }
            )
        }
        .onChange(of: store.selectedRepositoryID) { _, selectedID in
            guard let selectedID,
                  let repository = store.repositories.first(where: { $0.id == selectedID }) else { return }
            promptIdentityScanIfNeeded(for: repository)
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
                    identityScanStore: identityScanStore,
                    runners: runners,
                    runner: runners.runner(for: repository.id),
                    onScanRepository: { repository in
                        forceIdentityRescan = true
                        identityScanRepository = repository
                    },
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

    private func sidebar(windowWidth: CGFloat) -> some View {
        RepositorySidebarView(
            windowWidth: windowWidth,
            seedWidth: seedWidth,
            sidebarWidth: $sidebarWidth,
            store: store,
            preferencesStore: preferencesStore,
            onSelectRepository: { repository in
                store.select(repository)
                promptIdentityScanIfNeeded(for: repository)
            },
            onOpenLocalRepository: { repository in
                promptIdentityScanIfNeeded(for: repository)
            }
        )
    }

    private func promptIdentityScanIfNeeded(for repository: Repository) {
        guard repository.source.isLocal else { return }
        guard !identityScanStore.hasCompletedResult(for: repository.id) else { return }
        guard !isIdentityScanPromptPresented else { return }
        guard identityScanRepository?.id != repository.id else { return }
        pendingIdentityScanRepository = repository
        isIdentityScanPromptPresented = true
    }
}
