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

    private var filteredTree: [MarkdownNode] {
        MarkdownFileTree.filter(tree, term: filterText)
    }

    private var selectedNode: MarkdownNode? {
        guard let selectedPath else { return nil }
        return findNode(path: selectedPath, in: tree)
    }

    var body: some View {
        HSplitView {
            explorer
                .frame(minWidth: 220, idealWidth: 300, maxWidth: 460)
            document
                .frame(minWidth: 380)
        }
        .frame(minHeight: 420)
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
            }
        }
        .padding(12)
        .onChange(of: selectedPath) { _, newValue in
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
                if let documentError {
                    ContentUnavailableView(
                        "Could Not Open Document",
                        systemImage: "exclamationmark.triangle",
                        description: Text(documentError)
                    )
                } else {
                    ScrollView {
                        MarkdownRenderedView(
                            blocks: documentBlocks,
                            baseURL: URL(fileURLWithPath: node.path).deletingLastPathComponent()
                        )
                        .padding(20)
                        .frame(maxWidth: 900, alignment: .leading)
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
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(node.name).font(.headline)
                Text(node.relativePath)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
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
        }
        .padding(12)
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
        guard let source = try? String(contentsOfFile: path, encoding: .utf8) else {
            documentError = "The file could not be read as UTF-8 text, or it is no longer at \(path)."
            return
        }
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
