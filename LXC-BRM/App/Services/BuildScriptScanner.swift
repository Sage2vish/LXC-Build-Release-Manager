import Foundation

struct BuildScanOptions {
    var buildFolderName = "build"
    var scriptsSubdirectory = "scripts"
    var scanSubdirectories = false
    var allowScriptsOutsideBuildScripts = false
    var gitHubToken = ""

    static let `default` = BuildScanOptions()

    init(
        buildFolderName: String = "build",
        scriptsSubdirectory: String = "scripts",
        scanSubdirectories: Bool = false,
        allowScriptsOutsideBuildScripts: Bool = false,
        gitHubToken: String = ""
    ) {
        self.buildFolderName = buildFolderName.isEmpty ? "build" : buildFolderName
        self.scriptsSubdirectory = scriptsSubdirectory.isEmpty ? "scripts" : scriptsSubdirectory
        self.scanSubdirectories = scanSubdirectories
        self.allowScriptsOutsideBuildScripts = allowScriptsOutsideBuildScripts
        self.gitHubToken = gitHubToken
    }

    init(preferences: Preferences) {
        self.init(
            buildFolderName: preferences.defaultBuildFolderName,
            scriptsSubdirectory: preferences.scriptsSubdirectory,
            scanSubdirectories: preferences.scanSubdirectoriesForBuild,
            allowScriptsOutsideBuildScripts: preferences.allowScriptsOutsideBuildScripts,
            gitHubToken: preferences.gitHubToken
        )
    }
}

/// Resolves script paths before presentation or execution so status badges cannot be spoofed by display text.
enum BuildScriptPathResolver {
    static func canonicalIdentifier(for path: String, isRemote: Bool = false) -> String {
        if isRemote { return "remote:\(path.lowercased())" }

        let url = URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL
        if let values = try? url.resourceValues(forKeys: [.fileResourceIdentifierKey]),
           let identifier = values.fileResourceIdentifier {
            return "file:\(String(describing: identifier))"
        }
        return "path:\(normalizedPath(path, caseSensitive: false))"
    }

    static func standardScriptsDirectory(repositoryPath: String, options: BuildScanOptions) -> String {
        URL(fileURLWithPath: repositoryPath)
            .appendingPathComponent(options.buildFolderName, isDirectory: true)
            .appendingPathComponent(options.scriptsSubdirectory, isDirectory: true)
            .standardizedFileURL
            .path
    }

    static func location(
        for scriptPath: String,
        repositoryPath: String,
        options: BuildScanOptions,
        isPersistedPath: Bool = false,
        caseSensitive: Bool = false
    ) -> BuildScriptLocation {
        guard FileManager.default.fileExists(atPath: scriptPath) else {
            return isPersistedPath ? .stale : .missing
        }

        let parentPath = URL(fileURLWithPath: scriptPath)
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
            .standardizedFileURL
            .path
        let standardPath = standardScriptsDirectory(repositoryPath: repositoryPath, options: options)
        if pathsEqual(parentPath, standardPath, caseSensitive: caseSensitive) {
            return .standardFolder
        }
        if isWithin(scriptPath, rootPath: repositoryPath, caseSensitive: caseSensitive) {
            return .repository
        }
        return .outsideRepository
    }

    static func isWithin(_ candidatePath: String, rootPath: String, caseSensitive: Bool = false) -> Bool {
        let candidate = normalizedPath(candidatePath, caseSensitive: caseSensitive)
        let root = normalizedPath(rootPath, caseSensitive: caseSensitive)
        return candidate == root || candidate.hasPrefix(root.hasSuffix("/") ? root : "\(root)/")
    }

    static func normalizedPath(_ path: String, caseSensitive: Bool = false) -> String {
        let normalized = URL(fileURLWithPath: path)
            .resolvingSymlinksInPath()
            .standardizedFileURL
            .path
            .precomposedStringWithCanonicalMapping
        return caseSensitive ? normalized : normalized.lowercased()
    }

    static func pathsEqual(_ lhs: String, _ rhs: String, caseSensitive: Bool = false) -> Bool {
        normalizedPath(lhs, caseSensitive: caseSensitive) == normalizedPath(rhs, caseSensitive: caseSensitive)
    }
}

enum BuildScriptScanner {
    static func label(for fileName: String) -> String {
        fileName.hasSuffix(".sh") ? String(fileName.dropLast(3)) : fileName
    }

    static func scanLocal(
        path: String,
        options: BuildScanOptions = .default,
        additionalScriptPaths: [String] = []
    ) -> BuildScanResult {
        let rootResult = scanLocalRoot(path: path, repositoryPath: path, options: options)
        let discoveredResult: BuildScanResult

        if case .missingBuildFolder = rootResult, options.scanSubdirectories {
            discoveredResult = scanFirstNestedBuildFolder(path: path, repositoryPath: path, options: options) ?? rootResult
        } else {
            discoveredResult = rootResult
        }

        var scripts: [BuildScript] = {
            if case .success(let scripts) = discoveredResult { return scripts }
            return []
        }()

        for scriptPath in additionalScriptPaths.sorted() {
            let script = localScript(
                at: URL(fileURLWithPath: scriptPath),
                repositoryPath: path,
                options: options,
                isPersistedPath: true
            )
            if !scripts.contains(where: { $0.id == script.id || $0.path == script.path }) {
                scripts.append(script)
            }
        }

        if !scripts.isEmpty {
            return .success(scripts: scripts.sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending })
        }
        return discoveredResult
    }

    static func scanGitHub(urlString: String, options: BuildScanOptions = .default) async -> BuildScanResult {
        guard let (owner, repo) = parseOwnerRepo(from: urlString) else {
            return .unreachable("Not a valid GitHub repository URL")
        }

        let scriptsPath = "\(options.buildFolderName)/\(options.scriptsSubdirectory)"
        let scriptsResult = await fetchContents(owner: owner, repo: repo, path: scriptsPath, token: options.gitHubToken)
        switch scriptsResult {
        case .found(let entries):
            let shellFiles = entries
                .filter { $0.type == "file" && $0.name.hasSuffix(".sh") }
                .map(\.name)
                .sorted()
            guard !shellFiles.isEmpty else { return .emptyScripts }
            return .success(scripts: shellFiles.map { fileName in
                let scriptPath = "\(scriptsPath)/\(fileName)"
                return BuildScript(
                    fileName: fileName,
                    label: label(for: fileName),
                    path: scriptPath,
                    id: "github:\(owner.lowercased())/\(repo.lowercased())/\(scriptPath.lowercased())",
                    location: .standardFolder,
                    isRemote: true
                )
            })

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

    private static func scanLocalRoot(path: String, repositoryPath: String, options: BuildScanOptions) -> BuildScanResult {
        let scriptsFolderPath = BuildScriptPathResolver.standardScriptsDirectory(repositoryPath: path, options: options)
        let buildFolderPath = URL(fileURLWithPath: path)
            .appendingPathComponent(options.buildFolderName, isDirectory: true)
            .standardizedFileURL
            .path
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: buildFolderPath, isDirectory: &isDirectory), isDirectory.boolValue else {
            return .missingBuildFolder
        }
        guard FileManager.default.fileExists(atPath: scriptsFolderPath, isDirectory: &isDirectory), isDirectory.boolValue,
              let entries = try? FileManager.default.contentsOfDirectory(
                  at: URL(fileURLWithPath: scriptsFolderPath),
                  includingPropertiesForKeys: [.isRegularFileKey],
                  options: [.skipsHiddenFiles]
              ) else {
            return .emptyScripts
        }

        let scripts = entries
            .filter(isRunnableScript)
            .map { localScript(at: $0, repositoryPath: repositoryPath, options: options) }
            .sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }
        return scripts.isEmpty ? .emptyScripts : .success(scripts: scripts)
    }

    private static func scanFirstNestedBuildFolder(path: String, repositoryPath: String, options: BuildScanOptions) -> BuildScanResult? {
        guard let entries = try? FileManager.default.contentsOfDirectory(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for entry in entries.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let values = try? entry.resourceValues(forKeys: [.isDirectoryKey])
            guard values?.isDirectory == true else { continue }
            let result = scanLocalRoot(path: entry.path, repositoryPath: repositoryPath, options: options)
            if result != .missingBuildFolder { return result }
        }
        return nil
    }

    private static func isRunnableScript(_ url: URL) -> Bool {
        url.pathExtension == "sh" || FileManager.default.isExecutableFile(atPath: url.path)
    }

    private static func localScript(
        at url: URL,
        repositoryPath: String,
        options: BuildScanOptions,
        isPersistedPath: Bool = false
    ) -> BuildScript {
        let path = url.standardizedFileURL.path
        return BuildScript(
            fileName: url.lastPathComponent,
            label: displayLabel(for: url),
            path: path,
            location: BuildScriptPathResolver.location(
                for: path,
                repositoryPath: repositoryPath,
                options: options,
                isPersistedPath: isPersistedPath
            ),
            parameters: parameterDefinitions(in: url)
        )
    }

    private static func displayLabel(for url: URL) -> String {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return label(for: url.lastPathComponent)
        }
        for line in content.split(separator: "\n").prefix(40) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasPrefix("# lxc:label ") {
                return String(trimmed.dropFirst("# lxc:label ".count)).trimmingCharacters(in: .whitespaces)
            }
        }
        return label(for: url.lastPathComponent)
    }

    private static func parameterDefinitions(in url: URL) -> [BuildParameterDefinition] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return content
            .split(separator: "\n")
            .prefix(80)
            .compactMap { parameterDefinition(from: String($0)) }
    }

    private static func parameterDefinition(from line: String) -> BuildParameterDefinition? {
        let prefix = "# lxc:param "
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.lowercased().hasPrefix(prefix) else { return nil }

        let parts = trimmed.dropFirst(prefix.count).split(separator: " ", omittingEmptySubsequences: true)
        guard let keyPart = parts.first, !keyPart.isEmpty else { return nil }
        var attributes: [String: String] = [:]
        for part in parts.dropFirst() {
            let pair = part.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            if pair.count == 2 {
                attributes[String(pair[0]).lowercased()] = String(pair[1])
            } else if part.lowercased() == "required" {
                attributes["required"] = "true"
            }
        }

        let kind = BuildParameterKind(rawValue: attributes["type"]?.lowercased() ?? "text") ?? .text
        let options = attributes["options"]?.split(separator: ",").map { String($0) } ?? []
        return BuildParameterDefinition(
            key: String(keyPart),
            label: attributes["label"]?.replacingOccurrences(of: "_", with: " "),
            kind: kind,
            options: options,
            isRequired: attributes["required"] == "true",
            defaultValue: attributes["default"] ?? "",
            placeholder: attributes["placeholder"]?.replacingOccurrences(of: "_", with: " ") ?? "",
            helpText: attributes["help"]?.replacingOccurrences(of: "_", with: " ") ?? "",
            dependsOnKey: attributes["depends_on"],
            visibleWhenValue: attributes["visible_when"]
        )
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
            if http.statusCode == 404 { return .notFound }
            guard http.statusCode == 200 else {
                return .error("GitHub API returned status \(http.statusCode)")
            }
            return .found(try JSONDecoder().decode([GitHubContentEntry].self, from: data))
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
