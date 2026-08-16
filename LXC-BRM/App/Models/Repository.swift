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

struct Repository: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var source: RepositorySource
    var lastAccessed: Date
    var isPinned: Bool

    init(id: UUID = UUID(), name: String, source: RepositorySource, lastAccessed: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.name = name
        self.source = source
        self.lastAccessed = lastAccessed
        self.isPinned = isPinned
    }
}
