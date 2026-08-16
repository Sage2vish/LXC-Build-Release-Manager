import Foundation

enum BuildScriptScanner {
    static func label(for fileName: String) -> String {
        fileName.hasSuffix(".sh") ? String(fileName.dropLast(3)) : fileName
    }

    static func scanLocal(path: String) -> BuildScanResult {
        let fileManager = FileManager.default
        let buildFolder = (path as NSString).appendingPathComponent("build")
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: buildFolder, isDirectory: &isDirectory), isDirectory.boolValue else {
            return .missingBuildFolder
        }

        let scriptsFolder = (buildFolder as NSString).appendingPathComponent("scripts")
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

    static func scanGitHub(urlString: String) async -> BuildScanResult {
        guard let (owner, repo) = parseOwnerRepo(from: urlString) else {
            return .unreachable("Not a valid GitHub repository URL")
        }

        let scriptsResult = await fetchContents(owner: owner, repo: repo, path: "build/scripts")
        switch scriptsResult {
        case .found(let entries):
            let shFiles = entries
                .filter { $0.type == "file" && $0.name.hasSuffix(".sh") }
                .map(\.name)
                .sorted()
            guard !shFiles.isEmpty else { return .emptyScripts }
            let scripts = shFiles.map { fileName in
                BuildScript(fileName: fileName, label: label(for: fileName), path: "build/scripts/\(fileName)")
            }
            return .success(scripts: scripts)

        case .notFound:
            let buildResult = await fetchContents(owner: owner, repo: repo, path: "build")
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

    private static func fetchContents(owner: String, repo: String, path: String) async -> ContentsFetch {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repo)/contents/\(path)") else {
            return .error("Invalid GitHub API URL")
        }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

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
