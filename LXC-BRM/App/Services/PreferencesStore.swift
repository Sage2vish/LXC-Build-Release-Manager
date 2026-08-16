import Foundation

@MainActor
final class PreferencesStore: ObservableObject {
    @Published private(set) var preferences: Preferences

    private let storeURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("LXC-BRM", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        storeURL = folder.appendingPathComponent("preferences.json")
        preferences = Self.load(from: storeURL) ?? .recommendedDefaults
    }

    func save(_ newPreferences: Preferences) {
        preferences = newPreferences
        persist()
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(preferences) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    private static func load(from url: URL) -> Preferences? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Preferences.self, from: data)
    }
}
