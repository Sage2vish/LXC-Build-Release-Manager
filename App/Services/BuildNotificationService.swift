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

        // "Group multiple notifications": a shared thread identifier makes Notification Centre
        // stack this repository's builds instead of listing every event separately.
        if preferences.groupMultipleNotifications {
            content.threadIdentifier = repository.id.uuidString
        }

        // "Notification duration": anything longer than the banner default has to be a
        // time-sensitive alert, otherwise macOS dismisses it on its own schedule.
        content.interruptionLevel = Self.wantsPersistentBanner(preferences) ? .timeSensitive : .active

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    /// True when the user asked for a longer-lived banner than the macOS default.
    static func wantsPersistentBanner(_ preferences: Preferences) -> Bool {
        switch preferences.notificationDuration {
        case "Until dismissed", "10 seconds": return true
        default: return false
        }
    }

    /// A build counts as long-running once it passes this threshold, which is what
    /// `notifyLongRunningBuildCompleted` gates on.
    static let longRunningThreshold: TimeInterval = 60

    /// Whether a finished build should notify, taking the long-running preference into account.
    /// When `notifyLongRunningBuildCompleted` is off, quick builds still notify normally; when it
    /// is on, a build that ran past the threshold always notifies even if the per-status toggle
    /// for its outcome is off.
    static func shouldNotifyOnCompletion(
        durationSeconds: TimeInterval,
        statusEnabled: Bool,
        preferences: Preferences
    ) -> Bool {
        if preferences.notifyLongRunningBuildCompleted, durationSeconds >= longRunningThreshold {
            return true
        }
        return statusEnabled
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
