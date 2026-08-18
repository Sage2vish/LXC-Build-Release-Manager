import SwiftUI
import AppKit

/// The Docs tab: markdown files on the left, the rendered document on the right.
struct MarkdownExplorerView: View {
    let repository: Repository

    @State private var tree: [MarkdownNode] = []
    @State private var selectedPath: String?
    @State private var documentBlocks: [MarkdownBlock] = []
    @State private var documentError: String?
    @State private var filterText = ""
    @State private var isScanning = false
    @State private var scanTask: Task<Void, Never>?
    @State private var viewMode: ViewMode = .preview
    @State private var isEditing = false
    @State private var sourceText = ""
    @State private var draftText = ""
    @State private var loadedAt: Date?
    @State private var saveError: String?

    /// Mutually exclusive by construction — there is no state where both are active.
    enum ViewMode: String, CaseIterable, Identifiable {
        case preview = "Preview"
        case source = "Source"
        var id: String { rawValue }
    }

    private var hasUnsavedChanges: Bool { isEditing && draftText != sourceText }

    private var filteredTree: [MarkdownNode] {
        MarkdownFileTree.filter(tree, term: filterText)
    }

    private var selectedNode: MarkdownNode? {
        guard let selectedPath else { return nil }
        return findNode(path: selectedPath, in: tree)
    }

    var body: some View {
        HSplitView {
            // No width constraints at all. Every minimum, ideal or maximum written here does two
            // unwanted things: it adds into the window's own minimum width, and — because an
            // ideal is re-applied on each layout pass — it drags the divider back under the
            // pointer. AppKit sizes these two panes from their content and then lets the divider
            // decide, which is what "flexible" actually means.
            explorer
            document
        }
        // No cursor override: this modifier applied to the whole tab, not to the divider, so
        // the pointer became a resize arrow anywhere over the Docs tab and lied about what
        // could be dragged. AppKit already shows the right cursor over an HSplitView divider.
        //
        // No minimum height either: the tab fills whatever the window gives it and compresses
        // with it. A 420pt floor meant a short window clipped the document instead of scrolling
        // it.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: repository.id) { await rescan() }
        .onDisappear { scanTask?.cancel() }
    }

    // MARK: Explorer

    private var explorer: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Documents").font(.headline)
                Spacer()
                if isScanning {
                    ProgressView().controlSize(.small)
                } else {
                    Text("\(MarkdownFileTree.fileCount(tree))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("\(MarkdownFileTree.fileCount(tree)) markdown files")
                }
                Button {
                    Task { await rescan() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(isScanning)
                .accessibilityLabel("Rescan documents")
            }

            TextField("Filter files", text: $filterText)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel("Filter documents")

            if !isScanning && tree.isEmpty {
                ContentUnavailableView(
                    "No Markdown Files",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("This repository has no .md files outside build and dependency folders.")
                )
            } else if filteredTree.isEmpty {
                Text("Nothing matches “\(filterText)”.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                List(filteredTree, children: \.optionalChildren, selection: $selectedPath) { node in
                    Label {
                        Text(node.name).lineLimit(1).truncationMode(.middle)
                    } icon: {
                        Image(systemName: node.isDirectory ? "folder" : "doc.text")
                            .foregroundStyle(node.isDirectory ? .secondary : Color.accentColor)
                    }
                    .tag(node.path)
                    .accessibilityLabel(node.isDirectory ? "Folder \(node.name)" : "Document \(node.relativePath)")
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                // Matches the rounded cards used elsewhere, instead of a hard-edged rectangle.
                .background(Color.sectionSurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.sectionBorder, lineWidth: 1)
                )
            }
        }
        .padding(12)
        .onChange(of: selectedPath) { oldValue, newValue in
            // Switching files must not silently throw away an edit.
            if hasUnsavedChanges, !confirmDiscardIfNeeded() {
                selectedPath = oldValue
                return
            }
            loadDocument(path: newValue)
        }
    }

    // MARK: Document

    @ViewBuilder
    private var document: some View {
        if let node = selectedNode, !node.isDirectory {
            VStack(alignment: .leading, spacing: 0) {
                documentHeader(node)
                Divider()
                if let saveError {
                    Label(saveError, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.top, 6)
                }
                if let documentError {
                    ContentUnavailableView(
                        "Could Not Open Document",
                        systemImage: "exclamationmark.triangle",
                        description: Text(documentError)
                    )
                } else if viewMode == .source {
                    MarkdownSourceView(text: sourceText, isEditing: isEditing, draft: $draftText)
                } else {
                    ScrollView {
                        MarkdownRenderedView(
                            blocks: documentBlocks,
                            baseURL: URL(fileURLWithPath: node.path).deletingLastPathComponent()
                        )
                        .padding(24)
                        // The document flows to the pane, full stop. No column cap: the divider
                        // is how a reader chooses their line length, and a hidden ceiling only
                        // makes the pane stop responding at wide window sizes.
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } else {
            ContentUnavailableView(
                "Select a Document",
                systemImage: "doc.richtext",
                description: Text("Choose a markdown file on the left to read it here.")
            )
        }
    }

    private func documentHeader(_ node: MarkdownNode) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.name).font(.headline)
                    Text(node.relativePath)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                // The picker sits next to the title it controls, not pushed to the far right.
                Picker("", selection: $viewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                // Sized by its own labels, in whatever language they are written.
                .fixedSize()
                .accessibilityLabel("Document view mode")
                .onChange(of: viewMode) { _, newValue in
                    // Editing only exists inside Source.
                    if newValue == .preview, !confirmDiscardIfNeeded() {
                        viewMode = .source
                        return
                    }
                    if newValue == .preview { isEditing = false }
                }

                Spacer()
                headerActions(node)
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private func headerActions(_ node: MarkdownNode) -> some View {
        if isEditing {
            Button("Cancel") {
                draftText = sourceText
                isEditing = false
                saveError = nil
            }
            .accessibilityLabel("Cancel editing")

            Button("Save") { save(node) }
                .buttonStyle(.borderedProminent)
                .disabled(draftText == sourceText)
                .keyboardShortcut("s", modifiers: [.command])
                .accessibilityLabel("Save document")
        } else {
            // Edit is reachable only from Source: Preview is a reader and must never write.
            if viewMode == .source {
                Button {
                    draftText = sourceText
                    saveError = nil
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .accessibilityLabel("Edit document source")
            }
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: node.path)])
            } label: {
                Label("Reveal in Finder", systemImage: "folder")
            }
            .accessibilityLabel("Reveal document in Finder")
            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(node.path, forType: .string)
            } label: {
                Label("Copy Path", systemImage: "doc.on.doc")
            }
            .accessibilityLabel("Copy document path")

            Button {
                // Hands the file to whatever the user has set for .md — their editor, not ours.
                NSWorkspace.shared.open(URL(fileURLWithPath: node.path))
            } label: {
                Label("Open in Editor", systemImage: "arrow.up.forward.app")
            }
            .accessibilityLabel("Open document in the default editor")
        }
    }

    private func save(_ node: MarkdownNode) {
        switch MarkdownDocumentStore.save(draftText, to: node.path, loadedAt: loadedAt) {
        case .saved:
            sourceText = draftText
            documentBlocks = MarkdownParser.parse(draftText)
            loadedAt = MarkdownDocumentStore.modificationDate(of: node.path)
            isEditing = false
            saveError = nil
        case .changedOnDisk:
            saveError = "This file changed on disk since it was opened. Reload it before saving, or your edit would overwrite that change."
        case .failed(let reason):
            saveError = "Could not save: \(reason)"
        }
    }

    /// Returns false when the user chose to keep editing.
    private func confirmDiscardIfNeeded() -> Bool {
        guard hasUnsavedChanges else { return true }
        let alert = NSAlert()
        alert.messageText = "Discard unsaved changes?"
        alert.informativeText = "This document has edits that have not been saved."
        alert.addButton(withTitle: "Discard")
        alert.addButton(withTitle: "Keep Editing")
        alert.alertStyle = .warning
        if alert.runModal() == .alertFirstButtonReturn {
            draftText = sourceText
            isEditing = false
            return true
        }
        return false
    }

    // MARK: Loading

    private func rescan() async {
        guard let root = repository.localPath else {
            tree = []
            return
        }
        scanTask?.cancel()
        isScanning = true

        let found = await Task.detached(priority: .userInitiated) {
            MarkdownFileTree.build(rootPath: root)
        }.value

        tree = found
        isScanning = false

        // Keep the current selection if it survived the rescan, otherwise open something.
        if let selectedPath, findNode(path: selectedPath, in: found) != nil {
            loadDocument(path: selectedPath)
        } else if let first = MarkdownFileTree.firstFile(in: found) {
            selectedPath = first.path
        } else {
            selectedPath = nil
            documentBlocks = []
        }
    }

    private func loadDocument(path: String?) {
        documentError = nil
        documentBlocks = []
        guard let path, let node = findNode(path: path, in: tree), !node.isDirectory else { return }

        // The file can be deleted or replaced between the scan and this read.
        guard let source = MarkdownDocumentStore.read(path: path) else {
            documentError = "The file could not be read as UTF-8 text, or it is no longer at \(path)."
            return
        }
        sourceText = source
        draftText = source
        loadedAt = MarkdownDocumentStore.modificationDate(of: path)
        isEditing = false
        saveError = nil
        documentBlocks = MarkdownParser.parse(source)
    }

    private func findNode(path: String, in nodes: [MarkdownNode]) -> MarkdownNode? {
        for node in nodes {
            if node.path == path { return node }
            if let found = findNode(path: path, in: node.children) { return found }
        }
        return nil
    }
}

private extension MarkdownNode {
    /// `List(children:)` wants `nil` for leaves, otherwise it draws a disclosure arrow on files.
    var optionalChildren: [MarkdownNode]? {
        isDirectory && !children.isEmpty ? children : nil
    }
}
