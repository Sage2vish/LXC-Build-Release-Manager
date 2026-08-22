import SwiftUI
import AppKit

struct RepositorySidebarView: View {
    let windowWidth: CGFloat
    let seedWidth: CGFloat?
    @Binding var sidebarWidth: CGFloat
    @ObservedObject var store: RepositoryStore
    @ObservedObject var preferencesStore: PreferencesStore
    let onSelectRepository: (Repository) -> Void
    let onOpenLocalRepository: (Repository) -> Void

    @Environment(\.openSettings) private var openSettings

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

    var body: some View {
        VStack(spacing: 0) {
            repositoryList
            footer
        }
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width.rounded()
        } action: { width in
            guard width > 0 else { return }
            sidebarWidth = width
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
        .background(
            GlassSurface(
                .ultraThin,
                reduceTransparency: preferencesStore.preferences.reduceTransparency
            )
            .padding(.bottom, -24)
        )
    }

    private var repositoryList: some View {
        List {
            Section {
                ForEach(sortedRepositories) { repository in
                    repositorySidebarRow(repository)
                        .listRowBackground(boxBackground(for: repository, in: sortedRepositories))
                }
            } header: {
                repositoriesHeader
            }

            if !recentRepositories.isEmpty {
                Section {
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
                        .foregroundStyle(.primary)
                        .textCase(nil)
                        .padding(.leading, 4)
                        .padding(.top, 10)
                        .padding(.bottom, 6)
                        .accessibilityAddTraits(.isHeader)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .listSectionSeparator(.hidden, edges: .all)
        .listRowSeparator(.hidden, edges: .all)
        .environment(\.defaultMinListRowHeight, 0)
        .navigationTitle("Build Manager")
        .navigationSplitViewColumnWidth(
            min: LayoutMetrics.sidebarColumn(for: windowWidth).min,
            ideal: LayoutMetrics.sidebarColumn(for: seedWidth ?? windowWidth).ideal,
            max: LayoutMetrics.sidebarColumn(for: windowWidth).max
        )
        .background(
            SidebarWidthEnforcer(
                targetWidth: LayoutMetrics.sidebarColumn(for: seedWidth ?? windowWidth).ideal
            )
        )
        .toolbar(removing: .sidebarToggle)
    }

    private var repositoriesHeader: some View {
        HStack(spacing: 6) {
            Text("Repositories")
                .font(.headline)
                .foregroundStyle(.primary)
                .textCase(nil)
                .accessibilityAddTraits(.isHeader)
            Spacer()
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

    private var footer: some View {
        VStack(spacing: 8) {
            Button {
                guard let path = presentLocalFolderPickerPath() else { return }
                store.addLocalRepository(path: path)
                if let repository = store.selectedRepository {
                    onOpenLocalRepository(repository)
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
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(
            GlassSurface(
                .ultraThin,
                hairline: .top,
                reduceTransparency: preferencesStore.preferences.reduceTransparency
            )
        )
    }

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
        .onTapGesture { onSelectRepository(repository) }
        .contextMenu { contextMenu(for: repository) }
        .accessibilityLabel("\(repository.name), \(repository.source.displayPath)")
        .accessibilityHint("Select repository \(repository.name)")
    }

    private func recentRepositorySidebarRow(_ repository: Repository) -> some View {
        let isSelected = store.selectedRepositoryID == repository.id
        return HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
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
        .onTapGesture { onSelectRepository(repository) }
        .contextMenu { contextMenu(for: repository) }
        .accessibilityLabel("\(repository.name), \(repository.source.displayPath), recent repository")
        .accessibilityHint("Select recent repository \(repository.name)")
    }

    @ViewBuilder
    private func contextMenu(for repository: Repository) -> some View {
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

    private func boxBackground(for repository: Repository, in group: [Repository]) -> ListBoxRowBackground {
        let index = group.firstIndex(of: repository) ?? 0
        return ListBoxRowBackground(
            position: .init(index: index, count: group.count),
            isSelected: store.selectedRepositoryID == repository.id
        )
    }

    private func toggleSidebarPaths() {
        var updated = preferencesStore.preferences
        updated.showRepositoryPathInSidebar.toggle()
        preferencesStore.save(updated)
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

        private static func forgetStoredFrames(named autosaveName: NSSplitView.AutosaveName?) {
            let defaults = UserDefaults.standard
            var keys = ["NSSplitView Subview Frames \(autosaveName ?? "")"]
            keys += defaults.dictionaryRepresentation().keys.filter {
                $0.hasPrefix("NSSplitView Subview Frames")
            }
            for key in Set(keys) { defaults.removeObject(forKey: key) }
        }
    }
}
