import SwiftUI

@main
struct LXC_BRMApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)

        Settings {
            PreferencesView(store: PreferencesStore.shared, historyStore: BuildHistoryStore.shared)
        }
    }
}
