import AppKit
@preconcurrency import UserNotifications

@MainActor
final class BuildNotificationService {
    static let shared = BuildNotificationService()

    enum Kind {
        case started
        case succeeded
        case failed
        case cancelled
    }

    private let center = UNUserNotificationCenter.current()
    private var didRequestAuthorization = false

    func notify(_ kind: Kind, repository: Repository, script: BuildScript, preferences: Preferences) {
        guard shouldNotify(kind: kind, preferences: preferences) else { return }
        ensureAuthorizationIfNeeded { [weak self] in
            Task { @MainActor in
                self?.post(kind: kind, repository: repository, script: script, preferences: preferences)
            }
        }
    }

    private func shouldNotify(kind: Kind, preferences: Preferences) -> Bool {
        guard preferences.enableBuildNotifications else { return false }
        if preferences.notifyOnlyWhenNotInFocus, NSApp.isActive { return false }
        switch kind {
        case .started: return preferences.notifyBuildStarted
        case .succeeded: return preferences.notifyBuildSucceeded
        case .failed: return preferences.notifyBuildFailed
        case .cancelled: return preferences.notifyBuildCancelled
        }
    }

    private func ensureAuthorizationIfNeeded(_ completion: @escaping @Sendable () -> Void) {
        guard !didRequestAuthorization else { return }
        didRequestAuthorization = true
        let center = self.center
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else {
                Task { @MainActor in completion() }
                return
            }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                Task { @MainActor in completion() }
            }
        }
    }

    private func post(kind: Kind, repository: Repository, script: BuildScript, preferences: Preferences) {
        let content = UNMutableNotificationContent()
        content.title = repository.name
        content.body = bodyText(kind: kind, script: script)
        content.sound = preferences.notificationSound == "None" ? nil : .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    private func bodyText(kind: Kind, script: BuildScript) -> String {
        switch kind {
        case .started: return "Build started: \(script.label)"
        case .succeeded: return "Build succeeded: \(script.label)"
        case .failed: return "Build failed: \(script.label)"
        case .cancelled: return "Build cancelled: \(script.label)"
        }
    }
}
