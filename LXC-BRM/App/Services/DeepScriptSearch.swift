import Foundation

/// A `.sh` file found anywhere in the repository tree by the Auto Find walk.
struct DiscoveredScript: Identifiable, Hashable {
    let path: String
    let fileName: String
    let folderName: String
    /// Path relative to the repository root, for disambiguating same-named scripts.
    let relativePath: String
    /// True when this path is already present in the repository's scripts table.
    let isAlreadyAdded: Bool

    var id: String { path }

    var label: String {
        fileName.hasSuffix(".sh") ? String(fileName.dropLast(3)) : fileName
    }
}

/// Recursively walks a repository for runnable shell scripts.
///
/// The regular scan only looks at `/build/scripts/`. This digs through the whole tree so the
/// user can pull in scripts that live anywhere, then choose from the results.
enum DeepScriptSearch {
    /// Directories that never contain scripts worth offering, and which are large enough that
    /// walking them would dominate the search time.
    private static let skippedDirectories: Set<String> = [
        ".git", ".svn", ".hg",
        "node_modules", "Pods", "Carthage", "vendor",
        ".build", "build-output", "DerivedData", ".derivedData",
        ".swiftpm", ".gradle", "__pycache__", ".venv", "venv",
        ".next", "dist", "out", ".cache", ".idea", ".vscode"
    ]

    /// Walks `rootPath` for `.sh` files.
    ///
    /// - Parameter existingPaths: paths already in the scripts table, used to flag duplicates.
    /// - Note: Synchronous by necessity — `FileManager`'s enumerator cannot be iterated from an
    ///   async context. Call it inside a detached task so a large repository does not block the
    ///   main thread. It honours `Task.isCancelled` between entries so the sheet's Cancel button
    ///   can stop a long walk.
    static func search(
        rootPath: String,
        existingPaths: Set<String>
    ) -> [DiscoveredScript] {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: rootPath, isDirectory: &isDirectory), isDirectory.boolValue else {
            return []
        }

        let rootURL = URL(fileURLWithPath: rootPath, isDirectory: true)
        guard let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return []
        }

        var found: [DiscoveredScript] = []
        let rootComponentCount = rootURL.standardizedFileURL.pathComponents.count

        for case let url as URL in enumerator {
            if Task.isCancelled { return found.sorted { $0.relativePath < $1.relativePath } }

            let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey])

            if values?.isDirectory == true {
                if skippedDirectories.contains(url.lastPathComponent) {
                    enumerator.skipDescendants()
                }
                continue
            }

            guard values?.isRegularFile == true, url.pathExtension.lowercased() == "sh" else { continue }

            let path = url.standardizedFileURL.path
            let components = url.standardizedFileURL.pathComponents
            let relative = components.count > rootComponentCount
                ? components[rootComponentCount...].joined(separator: "/")
                : url.lastPathComponent

            found.append(
                DiscoveredScript(
                    path: path,
                    fileName: url.lastPathComponent,
                    folderName: url.deletingLastPathComponent().lastPathComponent,
                    relativePath: relative,
                    isAlreadyAdded: existingPaths.contains(path)
                )
            )
        }

        return found.sorted { $0.relativePath < $1.relativePath }
    }
}
