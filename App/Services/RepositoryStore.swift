import Foundation

@MainActor
final class RepositoryStore: ObservableObject {
    static let shared = RepositoryStore()

    @Published private(set) var repositories: [Repository] = []
    @Published var selectedRepositoryID: Repository.ID?

    /// Set when a load or save fails, so the UI can report it instead of losing data silently.
    @Published private(set) var lastError: AppDataError?

    private let repositoriesFile: JSONFileStore
    private let selectionFile: JSONFileStore
    private let rememberRecentRepositories: Bool

    init() {
        repositoriesFile = JSONFileStore(url: AppDataLocations.url(for: .repositories))
        selectionFile = JSONFileStore(url: AppDataLocations.url(for: .selectedRepository))

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

    /// Sets or clears the supplementary GitHub URL on a local repository, so a cloned repo can
    /// remember the origin it came from. Passing an empty or whitespace-only string clears it.
    func setGitHubURL(_ urlString: String, for repository: Repository) {
        guard let index = repositories.firstIndex(where: { $0.id == repository.id }) else { return }
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        repositories[index].gitHubURL = trimmed.isEmpty ? nil : trimmed
        save()
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

    private struct SelectionState: Codable { var selectedRepositoryID: UUID? }

    private func load() {
        switch repositoriesFile.load([Repository].self) {
        case .success(let decoded):
            guard let decoded else { return }
            repositories = decoded.sorted { $0.lastAccessed > $1.lastAccessed }
        case .failure(let error):
            lastError = error
        }
    }

    private func save() {
        guard rememberRecentRepositories else { return }
        if case .failure(let error) = repositoriesFile.save(repositories) {
            lastError = error
        }
    }

    private func loadSelectedRepositoryID() -> UUID? {
        switch selectionFile.load(SelectionState.self) {
        case .success(let state):
            return state?.selectedRepositoryID
        case .failure(let error):
            lastError = error
            return nil
        }
    }

    private func saveSelectedRepositoryID() {
        guard rememberRecentRepositories else { return }
        let state = SelectionState(selectedRepositoryID: selectedRepositoryID)
        if case .failure(let error) = selectionFile.save(state) {
            lastError = error
        }
    }
}
