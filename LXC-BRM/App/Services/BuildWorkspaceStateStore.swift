import Foundation

struct BuildWorkspaceState: Codable, Equatable {
    var selectedScriptID: String?
    var parameterValues: [String: BuildParameterValues]
    var addedScriptPaths: [String]

    static let empty = BuildWorkspaceState(selectedScriptID: nil, parameterValues: [:], addedScriptPaths: [])
}

/// Persists Build-tab-only choices without coupling discovery or process execution to SwiftUI state.
@MainActor
final class BuildWorkspaceStateStore: ObservableObject {
    static let shared = BuildWorkspaceStateStore()

    @Published private(set) var states: [UUID: BuildWorkspaceState] = [:]

    private let storeURL: URL

    init(storeURL: URL? = nil) {
        if let storeURL {
            self.storeURL = storeURL
            try? FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let folder = appSupport.appendingPathComponent("LXC-BRM", isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            self.storeURL = folder.appendingPathComponent("build-workspace-state.json")
        }
        load()
    }

    func state(for repositoryID: UUID) -> BuildWorkspaceState {
        states[repositoryID] ?? .empty
    }

    func select(scriptID: String?, for repositoryID: UUID) {
        update(repositoryID) { $0.selectedScriptID = scriptID }
    }

    func save(values: BuildParameterValues, for scriptID: String, repositoryID: UUID) {
        update(repositoryID) { $0.parameterValues[scriptID] = values }
    }

    func values(for scriptID: String, repositoryID: UUID) -> BuildParameterValues {
        state(for: repositoryID).parameterValues[scriptID] ?? [:]
    }

    func add(scriptPath: String, for repositoryID: UUID) {
        let standardizedPath = URL(fileURLWithPath: scriptPath).standardizedFileURL.path
        update(repositoryID) { state in
            guard !state.addedScriptPaths.contains(where: {
                BuildScriptPathResolver.pathsEqual($0, standardizedPath)
            }) else { return }
            state.addedScriptPaths.append(standardizedPath)
            state.addedScriptPaths.sort()
        }
    }

    func remove(scriptPath: String, for repositoryID: UUID) {
        update(repositoryID) { state in
            state.addedScriptPaths.removeAll { BuildScriptPathResolver.pathsEqual($0, scriptPath) }
        }
    }

    private func update(_ repositoryID: UUID, mutation: (inout BuildWorkspaceState) -> Void) {
        var value = states[repositoryID] ?? .empty
        mutation(&value)
        states[repositoryID] = value
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let decoded = try? JSONDecoder().decode([UUID: BuildWorkspaceState].self, from: data) else { return }
        states = decoded
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(states) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }
}
