import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var runners: BuildRunnerRegistry?
    var preferencesStore: PreferencesStore?

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
}
