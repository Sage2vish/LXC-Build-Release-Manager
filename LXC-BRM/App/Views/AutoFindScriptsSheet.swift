import SwiftUI

/// Grid picker for the Auto Find walk: digs the whole repository for `.sh` files and lets the
/// user add all of them, add a selected subset, re-run the search, or back out.
struct AutoFindScriptsSheet: View {
    let repositoryRootPath: String
    let existingPaths: Set<String>
    let onAdd: ([String]) -> Void
    @Binding var isPresented: Bool

    @State private var results: [DiscoveredScript] = []
    @State private var selection: Set<String> = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var searchTask: Task<Void, Never>?

    private let columns = [GridItem(.adaptive(minimum: 230), spacing: 12)]

    /// Scripts that are not already in the table — the only ones worth adding.
    private var addableResults: [DiscoveredScript] {
        results.filter { !$0.isAlreadyAdded }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(minWidth: 640, idealWidth: 820, minHeight: 460, idealHeight: 560)
        .onAppear { startSearch() }
        .onDisappear { searchTask?.cancel() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Auto Find Build Scripts").font(.headline)
            Text("Searches every folder in this repository for .sh files.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(repositoryRootPath)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    @ViewBuilder
    private var content: some View {
        if isSearching {
            VStack(spacing: 12) {
                ProgressView()
                Text("Searching the repository…").font(.callout).foregroundStyle(.secondary)
                Text("\(results.count) found so far").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if results.isEmpty && hasSearched {
            ContentUnavailableView(
                "No Shell Scripts Found",
                systemImage: "doc.text.magnifyingglass",
                description: Text("Nothing with a .sh extension was found anywhere in this repository.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    ForEach(results) { script in
                        cell(for: script)
                    }
                }
                .padding(16)
            }
        }
    }

    private func cell(for script: DiscoveredScript) -> some View {
        let isSelected = selection.contains(script.path)
        return Button {
            toggle(script)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: script.isAlreadyAdded
                          ? "checkmark.circle.fill"
                          : (isSelected ? "checkmark.square.fill" : "square"))
                        .foregroundStyle(script.isAlreadyAdded ? .green : (isSelected ? Color.accentColor : .secondary))
                    Text(script.label)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                Label(script.folderName, systemImage: "folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(script.relativePath)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if script.isAlreadyAdded {
                    Text("Already added")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.10) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.primary.opacity(0.10),
                            lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(script.isAlreadyAdded)
        .help(script.path)
        .accessibilityLabel("\(script.label) in \(script.folderName)")
        .accessibilityValue(script.isAlreadyAdded ? "Already added" : (isSelected ? "Selected" : "Not selected"))
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if !isSearching && hasSearched {
                Text(summaryText).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Cancel", role: .cancel) {
                searchTask?.cancel()
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)

            Button("Search Again") { startSearch() }
                .disabled(isSearching)

            Button("Add Selected") { add(paths: selection) }
                .disabled(isSearching || selection.isEmpty)

            Button("Add All") { add(paths: Set(addableResults.map(\.path))) }
                .buttonStyle(.borderedProminent)
                .disabled(isSearching || addableResults.isEmpty)
        }
        .padding(16)
    }

    private var summaryText: String {
        let total = results.count
        let addable = addableResults.count
        let already = total - addable
        var parts = ["\(total) script\(total == 1 ? "" : "s") found"]
        if already > 0 { parts.append("\(already) already added") }
        if !selection.isEmpty { parts.append("\(selection.count) selected") }
        return parts.joined(separator: " · ")
    }

    private func toggle(_ script: DiscoveredScript) {
        guard !script.isAlreadyAdded else { return }
        if selection.contains(script.path) {
            selection.remove(script.path)
        } else {
            selection.insert(script.path)
        }
    }

    private func startSearch() {
        searchTask?.cancel()
        selection = []
        results = []
        isSearching = true
        let root = repositoryRootPath
        let existing = existingPaths
        searchTask = Task {
            // Detached so the filesystem walk stays off the main thread.
            let found = await Task.detached(priority: .userInitiated) {
                DeepScriptSearch.search(rootPath: root, existingPaths: existing)
            }.value
            guard !Task.isCancelled else { return }
            await MainActor.run {
                results = found
                isSearching = false
                hasSearched = true
            }
        }
    }

    private func add(paths: Set<String>) {
        guard !paths.isEmpty else { return }
        // Preserve the on-screen order rather than the set's arbitrary order.
        let ordered = results.map(\.path).filter { paths.contains($0) }
        onAdd(ordered)
        isPresented = false
    }
}
