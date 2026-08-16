import Foundation

struct BuildScanOptions {
    var buildFolderName = "build"
    var scriptsSubdirectory = "scripts"
    var scanSubdirectories = false
    var gitHubToken = ""

    static let `default` = BuildScanOptions()

    init(buildFolderName: String = "build", scriptsSubdirectory: String = "scripts", scanSubdirectories: Bool = false, gitHubToken: String = "") {
        self.buildFolderName = buildFolderName.isEmpty ? "build" : buildFolderName
        self.scriptsSubdirectory = scriptsSubdirectory.isEmpty ? "scripts" : scriptsSubdirectory
        self.scanSubdirectories = scanSubdirectories
        self.gitHubToken = gitHubToken
    }

    init(preferences: Preferences) {
        self.init(
            buildFolderName: preferences.defaultBuildFolderName,
            scriptsSubdirectory: preferences.scriptsSubdirectory,
            scanSubdirectories: preferences.scanSubdirectoriesForBuild,
            gitHubToken: preferences.gitHubToken
        )
    }
}

enum BuildScriptScanner {
    static func label(for fileName: String) -> String {
        fileName.hasSuffix(".sh") ? String(fileName.dropLast(3)) : fileName
    }

    static func scanLocal(path: String, options: BuildScanOptions = .default) -> BuildScanResult {
        if let direct = scanLocalRoot(path: path, options: options) {
            return direct
        }

        guard options.scanSubdirectories else {
            return .missingBuildFolder
        }

        let fileManager = FileManager.default
        guard let entries = try? fileManager.contentsOfDirectory(atPath: path) else {
            return .missingBuildFolder
        }

        for entry in entries.sorted() {
            let subPath = (path as NSString).appendingPathComponent(entry)
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: subPath, isDirectory: &isDirectory), isDirectory.boolValue else { continue }
            if let found = scanLocalRoot(path: subPath, options: options) {
                return found
            }
        }
        return .missingBuildFolder
    }

    /// Scans exactly `path` (no subdirectory recursion) for the configured build/scripts layout.
    /// Returns nil only when `path` itself has no build folder, so callers can fall back to scanning subdirectories.
    private static func scanLocalRoot(path: String, options: BuildScanOptions) -> BuildScanResult? {
        let fileManager = FileManager.default
        let buildFolder = (path as NSString).appendingPathComponent(options.buildFolderName)
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: buildFolder, isDirectory: &isDirectory), isDirectory.boolValue else {
            return nil
        }

        let scriptsFolder = (buildFolder as NSString).appendingPathComponent(options.scriptsSubdirectory)
        guard fileManager.fileExists(atPath: scriptsFolder, isDirectory: &isDirectory), isDirectory.boolValue,
              let entries = try? fileManager.contentsOfDirectory(atPath: scriptsFolder) else {
            return .emptyScripts
        }

        let shFiles = entries.filter { $0.hasSuffix(".sh") }.sorted()
        guard !shFiles.isEmpty else { return .emptyScripts }

        let scripts = shFiles.map { fileName in
            BuildScript(
                fileName: fileName,
                label: label(for: fileName),
                path: (scriptsFolder as NSString).appendingPathComponent(fileName)
            )
        }
        return .success(scripts: scripts)
    }

    static func scanGitHub(urlString: String, options: BuildScanOptions = .default) async -> BuildScanResult {
        guard let (owner, repo) = parseOwnerRepo(from: urlString) else {
            return .unreachable("Not a valid GitHub repository URL")
        }

        let scriptsPath = "\(options.buildFolderName)/\(options.scriptsSubdirectory)"
        let scriptsResult = await fetchContents(owner: owner, repo: repo, path: scriptsPath, token: options.gitHubToken)
        switch scriptsResult {
        case .found(let entries):
            let shFiles = entries
                .filter { $0.type == "file" && $0.name.hasSuffix(".sh") }
                .map(\.name)
                .sorted()
            guard !shFiles.isEmpty else { return .emptyScripts }
            let scripts = shFiles.map { fileName in
                BuildScript(fileName: fileName, label: label(for: fileName), path: "\(scriptsPath)/\(fileName)")
            }
            return .success(scripts: scripts)

        case .notFound:
            let buildResult = await fetchContents(owner: owner, repo: repo, path: options.buildFolderName, token: options.gitHubToken)
            switch buildResult {
            case .found:
                return .emptyScripts
            case .notFound:
                return .missingBuildFolder
            case .error(let message):
                return .unreachable(message)
            }

        case .error(let message):
            return .unreachable(message)
        }
    }

    private struct GitHubContentEntry: Decodable {
        let name: String
        let type: String
    }

    private enum ContentsFetch {
        case found([GitHubContentEntry])
        case notFound
        case error(String)
    }

    private static func fetchContents(owner: String, repo: String, path: String, token: String) async -> ContentsFetch {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)") else {
            return .error("Invalid GitHub API URL")
        }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .error("No response from GitHub")
            }
            if http.statusCode == 404 {
                return .notFound
            }
            guard http.statusCode == 200 else {
                return .error("GitHub API returned status \(http.statusCode)")
            }
            let entries = try JSONDecoder().decode([GitHubContentEntry].self, from: data)
            return .found(entries)
        } catch {
            return .error(error.localizedDescription)
        }
    }

    private static func parseOwnerRepo(from urlString: String) -> (owner: String, repo: String)? {
        guard let url = URL(string: urlString), let host = url.host, host.contains("github.com") else {
            return nil
        }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.count >= 2 else { return nil }
        var repo = parts[1]
        if repo.hasSuffix(".git") { repo = String(repo.dropLast(4)) }
        return (parts[0], repo)
    }
}
