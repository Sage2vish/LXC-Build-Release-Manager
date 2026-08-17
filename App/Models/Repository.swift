import Foundation

enum RepositorySource: Codable, Hashable {
    case local(path: String)
    case github(url: String)

    var displayPath: String {
        switch self {
        case .local(let path): return path
        case .github(let url): return url
        }
    }

    var isLocal: Bool {
        if case .local = self { return true }
        return false
    }
}

/// Validation for the supplementary GitHub URL a local repository can record.
///
/// Kept out of the view so the accept/reject rules can be tested directly rather than only
/// through the Settings text field.
enum GitHubURLValidator {
    enum Outcome: Equatable {
        /// The field was blank: the stored URL should be cleared.
        case cleared
        /// A usable GitHub URL, trimmed of surrounding whitespace.
        case valid(String)
        case invalid(String)
    }

    static let invalidMessage = "Enter a GitHub URL in the form https://github.com/owner/repo."

    static func evaluate(_ raw: String) -> Outcome {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .cleared }
        guard let url = URL(string: trimmed),
              let host = url.host?.lowercased(),
              host == "github.com" || host.hasSuffix(".github.com"),
              url.pathComponents.count >= 3 else {
            return .invalid(invalidMessage)
        }
        return .valid(trimmed)
    }
}

struct Repository: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var source: RepositorySource
    var lastAccessed: Date
    var isPinned: Bool
    /// Supplementary origin for a locally-cloned repo. `source` stays the origin-of-record;
    /// this only lets a local repo also remember the GitHub URL it came from. Optional and
    /// defaulted so `projects.json` files written before this field still decode.
    var gitHubURL: String?

    init(
        id: UUID = UUID(),
        name: String,
        source: RepositorySource,
        lastAccessed: Date = Date(),
        isPinned: Bool = false,
        gitHubURL: String? = nil
    ) {
        self.id = id
        self.name = name
        self.source = source
        self.lastAccessed = lastAccessed
        self.isPinned = isPinned
        self.gitHubURL = gitHubURL
    }

    /// The local folder path, when this repository has one.
    var localPath: String? {
        if case .local(let path) = source { return path }
        return nil
    }

    /// The GitHub URL from either the source itself or the supplementary field.
    var resolvedGitHubURL: String? {
        if case .github(let url) = source { return url }
        guard let gitHubURL, !gitHubURL.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        return gitHubURL
    }
}
