import Foundation

enum GitBranchReader {
    static func currentBranch(for repository: Repository) -> String? {
        guard case .local(let path) = repository.source else { return nil }
        let headURL = URL(fileURLWithPath: path).appendingPathComponent(".git/HEAD")
        guard let contents = try? String(contentsOf: headURL, encoding: .utf8) else { return nil }
        let trimmed = contents.trimmingCharacters(in: .whitespacesAndNewlines)

        let prefix = "ref: refs/heads/"
        if trimmed.hasPrefix(prefix) {
            return String(trimmed.dropFirst(prefix.count))
        }
        if trimmed.count >= 7 {
            return "detached @ \(trimmed.prefix(7))"
        }
        return nil
    }
}
