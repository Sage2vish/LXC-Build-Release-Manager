import SwiftUI

@main
struct BuildReleaseManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var preferencesStore = PreferencesStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .commands {
            LayoutCommands(preferencesStore: preferencesStore)
        }

        Settings {
            PreferencesView(store: PreferencesStore.shared, historyStore: BuildHistoryStore.shared)
        }
    }
}

/// View-menu entries for showing and hiding the three window panels.
/// `.sidebar` places the group inside the standard macOS View menu.
struct LayoutCommands: Commands {
    @ObservedObject var preferencesStore: PreferencesStore

    var body: some Commands {
        CommandGroup(after: .sidebar) {
            Divider()

            Toggle(
                "Show Repo Window (Left side)",
                isOn: preferencesStore.binding(\.showRepositorySidebar)
            )
            .keyboardShortcut("l", modifiers: [.command, .option])

            Toggle(
                "Show Detail View Window (Right Side)",
                isOn: preferencesStore.binding(\.showDetailInspector)
            )
            .keyboardShortcut("r", modifiers: [.command, .option])

            Toggle(
                "Show Status Bar (Bottom)",
                isOn: preferencesStore.binding(\.showStatusBar)
            )
            .keyboardShortcut("s", modifiers: [.command, .option])
        }
    }
}
