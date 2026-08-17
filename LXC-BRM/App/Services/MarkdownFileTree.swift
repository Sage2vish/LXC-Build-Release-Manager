import Foundation

/// A markdown file, or a folder containing them.
struct MarkdownNode: Identifiable, Equatable {
    let name: String
    let path: String
    let isDirectory: Bool
    /// Path relative to the repository root, used for display and filtering.
    let relativePath: String
    var children: [MarkdownNode]

    var id: String { path }

    /// Total markdown files at or below this node.
    var fileCount: Int {
        isDirectory ? children.reduce(0) { $0 + $1.fileCount } : 1
    }
}

/// Finds the markdown files in a repository and arranges them as a tree.
///
/// A flat list is unusable — this project alone has 67 markdown files — so folders are kept and
/// nested. Skips the same noise directories as `DeepScriptSearch`, for the same reason: nobody
/// wants `node_modules` READMEs in a documentation browser.
enum MarkdownFileTree {
    static let markdownExtensions: Set<String> = ["md", "markdown"]

    private static let skippedDirectories: Set<String> = [
        ".git", ".svn", ".hg",
        "node_modules", "Pods", "Carthage", "vendor",
        ".build", "build-output", "DerivedData", ".derivedData",
        ".swiftpm", ".gradle", "__pycache__", ".venv", "venv",
        ".next", "dist", "out", ".cache", ".idea", ".vscode",
        "Intermediates.noindex"
    ]

    static func shouldSkip(directoryName name: String) -> Bool {
        if skippedDirectories.contains(name) { return true }
        if name.hasPrefix("DerivedData") { return true }
        if name.hasSuffix(".build") { return true }
        if name.hasSuffix(".xcodeproj") || name.hasSuffix(".xcworkspace") { return true }
        return false
    }

    static func isMarkdown(_ url: URL) -> Bool {
        markdownExtensions.contains(url.pathExtension.lowercased())
    }

    /// Builds the tree for `rootPath`.
    ///
    /// - Note: Synchronous, and does real filesystem work. Call it inside a detached task so a
    ///   large repository cannot block the main thread. Honours `Task.isCancelled`.
    static func build(rootPath: String, fileManager: FileManager = .default) -> [MarkdownNode] {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: rootPath, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            return []
        }
        let root = URL(fileURLWithPath: rootPath, isDirectory: true)
        return children(of: root, root: root, fileManager: fileManager)
    }

    private static func children(of directory: URL, root: URL, fileManager: FileManager) -> [MarkdownNode] {
        if Task.isCancelled { return [] }
        guard let entries = try? fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var folders: [MarkdownNode] = []
        var files: [MarkdownNode] = []

        for entry in entries {
            let isDirectory = (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDirectory {
                guard !shouldSkip(directoryName: entry.lastPathComponent) else { continue }
                let nested = children(of: entry, root: root, fileManager: fileManager)
                // A folder with no markdown anywhere below it is not worth showing.
                guard !nested.isEmpty else { continue }
                folders.append(
                    MarkdownNode(
                        name: entry.lastPathComponent,
                        path: entry.standardizedFileURL.path,
                        isDirectory: true,
                        relativePath: relativePath(of: entry, from: root),
                        children: nested
                    )
                )
            } else if isMarkdown(entry) {
                files.append(
                    MarkdownNode(
                        name: entry.lastPathComponent,
                        path: entry.standardizedFileURL.path,
                        isDirectory: false,
                        relativePath: relativePath(of: entry, from: root),
                        children: []
                    )
                )
            }
        }

        // Folders first, then files, each alphabetically — stable between scans.
        folders.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        files.sort { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        return folders + files
    }

    private static func relativePath(of url: URL, from root: URL) -> String {
        let rootComponents = root.standardizedFileURL.pathComponents
        let components = url.standardizedFileURL.pathComponents
        guard components.count > rootComponents.count else { return url.lastPathComponent }
        return components[rootComponents.count...].joined(separator: "/")
    }

    /// Filters the tree to nodes matching `term`, keeping folders whose descendants match.
    static func filter(_ nodes: [MarkdownNode], term: String) -> [MarkdownNode] {
        let query = term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return nodes }

        return nodes.compactMap { node in
            if node.isDirectory {
                let matching = filter(node.children, term: query)
                // Keep a folder when it matches by name, or when anything inside it does.
                if !matching.isEmpty {
                    var copy = node
                    copy.children = matching
                    return copy
                }
                return node.name.lowercased().contains(query) ? node : nil
            }
            return node.relativePath.lowercased().contains(query) ? node : nil
        }
    }

    /// Total files in a tree.
    static func fileCount(_ nodes: [MarkdownNode]) -> Int {
        nodes.reduce(0) { $0 + $1.fileCount }
    }

    /// First file in the tree, used to select something sensible on open.
    static func firstFile(in nodes: [MarkdownNode]) -> MarkdownNode? {
        for node in nodes {
            if !node.isDirectory { return node }
            if let nested = firstFile(in: node.children) { return nested }
        }
        return nil
    }
}
