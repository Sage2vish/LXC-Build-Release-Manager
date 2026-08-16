import Foundation

@MainActor
final class RepositoryStore: ObservableObject {
    static let shared = RepositoryStore()

    @Published private(set) var repositories: [Repository] = []
    @Published var selectedRepositoryID: Repository.ID?

    private let storeURL: URL
    private let selectedStoreURL: URL
    private let rememberRecentRepositories: Bool

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("LXC-BRM", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        storeURL = folder.appendingPathComponent("projects.json")
        selectedStoreURL = folder.appendingPathComponent("selected-repository.json")

        let prefs = Preferences.loadFromDisk()
        rememberRecentRepositories = prefs.rememberRecentRepositories

        guard rememberRecentRepositories, prefs.automaticallyRestoreLastOpenedRepositories else { return }
        load()
        selectedRepositoryID = prefs.restoreLastOpenedRepository ? (loadSelectedRepositoryID() ?? repositories.first?.id) : repositories.first?.id
    }

    var selectedRepository: Repository? {
        repositories.first { $0.id == selectedRepositoryID }
    }

    func addLocalRepository(path: String) {
        let name = (path as NSString).lastPathComponent
        upsert(Repository(name: name, source: .local(path: path)))
    }

    func addGitHubRepository(urlString: String) {
        let name = URL(string: urlString)?.lastPathComponent ?? urlString
        upsert(Repository(name: name, source: .github(url: urlString)))
    }

    func remove(_ repository: Repository) {
        repositories.removeAll { $0.id == repository.id }
        if selectedRepositoryID == repository.id {
            selectedRepositoryID = repositories.first?.id
        }
        save()
        saveSelectedRepositoryID()
    }

    func togglePin(_ repository: Repository) {
        guard let index = repositories.firstIndex(where: { $0.id == repository.id }) else { return }
        repositories[index].isPinned.toggle()
        save()
    }

    func select(_ repository: Repository) {
        selectedRepositoryID = repository.id
        guard let index = repositories.firstIndex(where: { $0.id == repository.id }) else { return }
        repositories[index].lastAccessed = Date()
        save()
        saveSelectedRepositoryID()
    }

    private func upsert(_ repository: Repository) {
        if let index = repositories.firstIndex(where: { $0.source == repository.source }) {
            repositories[index].lastAccessed = Date()
            selectedRepositoryID = repositories[index].id
        } else {
            repositories.insert(repository, at: 0)
            selectedRepositoryID = repository.id
        }
        save()
        saveSelectedRepositoryID()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let decoded = try? decoder.decode([Repository].self, from: data) else { return }
        repositories = decoded.sorted { $0.lastAccessed > $1.lastAccessed }
    }

    private func save() {
        guard rememberRecentRepositories else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(repositories) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    private func loadSelectedRepositoryID() -> UUID? {
        struct SelectionState: Codable { var selectedRepositoryID: UUID? }
        guard let data = try? Data(contentsOf: selectedStoreURL) else { return nil }
        return try? JSONDecoder().decode(SelectionState.self, from: data).selectedRepositoryID
    }

    private func saveSelectedRepositoryID() {
        guard rememberRecentRepositories else { return }
        struct SelectionState: Codable { var selectedRepositoryID: UUID? }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(SelectionState(selectedRepositoryID: selectedRepositoryID)) else { return }
        try? data.write(to: selectedStoreURL, options: .atomic)
    }
}
