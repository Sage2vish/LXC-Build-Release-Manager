import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var runners: BuildRunnerRegistry?
    var preferencesStore: PreferencesStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Force the Dock/Finder icon to match the packaged asset, even if the system cache
        // is still holding onto an older generic placeholder from a previous launch.
        if let icon = NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = icon
        }
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard preferencesStore?.preferences.confirmBeforeQuittingDuringBuild == true,
              runners?.hasAnyRunningBuild == true else {
            return .terminateNow
        }

        let alert = NSAlert()
        alert.messageText = "A Build Is Still Running"
        alert.informativeText = "Quitting now will stop the running build. Quit anyway?"
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        return alert.runModal() == .alertFirstButtonReturn ? .terminateNow : .terminateCancel
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard let preferences = preferencesStore?.preferences else { return }
        runners?.cancelAll(preferences: preferences)
    }
}
