import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()

    @Published private(set) var preferences: Preferences
    @Published private(set) var lastError: AppDataError?

    private let storeURL: URL

    init() {
        storeURL = AppDataLocations.url(for: .preferences)
        preferences = Preferences.loadFromDisk()
    }

    func save(_ newPreferences: Preferences) {
        var updated = newPreferences
        if updated.saveLogsAutomatically != preferences.saveLogsAutomatically {
            updated.automaticallySaveLogs = updated.saveLogsAutomatically
        } else if updated.automaticallySaveLogs != preferences.automaticallySaveLogs {
            updated.saveLogsAutomatically = updated.automaticallySaveLogs
        }

        let launchAtLoginChanged = updated.launchAtLogin != preferences.launchAtLogin
        preferences = updated
        persist()
        if launchAtLoginChanged {
            applyLaunchAtLogin(enabled: updated.launchAtLogin)
        }
    }

    /// Two-way binding onto a single preference, so menu commands and views can
    /// toggle one flag without rebuilding the whole `Preferences` value at each call site.
    func binding<Value>(_ keyPath: WritableKeyPath<Preferences, Value>) -> Binding<Value> {
        Binding(
            get: { self.preferences[keyPath: keyPath] },
            set: { newValue in
                var updated = self.preferences
                updated[keyPath: keyPath] = newValue
                self.save(updated)
            }
        )
    }

    private func persist() {
        if case .failure(let error) = JSONFileStore(url: storeURL).save(preferences) {
            lastError = error
        }
    }

    private func applyLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Best effort only: the setting is still persisted even if macOS rejects the request.
            print("Launch at login update failed: \(error.localizedDescription)")
        }
    }
}
