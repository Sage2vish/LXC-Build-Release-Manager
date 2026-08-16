import Foundation
import CoreGraphics

enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case light, dark, system
    var id: String { rawValue }
    var label: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

enum DefaultLaunchTab: String, Codable, CaseIterable, Identifiable {
    case build = "Build"
    case logs = "Logs"
    case history = "History"
    case overview = "Overview"
    var id: String { rawValue }
}

struct EnvironmentVariableEntry: Codable, Identifiable, Hashable {
    var id = UUID()
    var key: String = ""
    var value: String = ""
}

struct Preferences: Codable, Equatable {
    // 01 General
    var launchAtLogin = false
    var restoreLastOpenedRepository = true
    var defaultLaunchTab: DefaultLaunchTab = .build
    var rememberRecentRepositories = true
    var maxRecentRepositories = 10
    var confirmBeforeQuittingDuringBuild = true
    var confirmBeforeClearing = true
    var checkForUpdatesAutomatically = true
    var updateChannel = "Stable (Recommended)"
    var language = "System Default"

    // 02 Repositories
    var defaultRepositoryRootDetection = true
    var defaultBuildFolderName = "build"
    var scriptsSubdirectory = "scripts"
    var logsSubdirectory = "logs"
    var scanSubdirectoriesForBuild = true
    var automaticallyRestoreLastOpenedRepositories = true
    var gitHubToken = ""
    var autoDetectRepositoriesOnStartup = true

    // 03 Build Execution
    var defaultShell = "/bin/zsh"
    var workingDirectoryChoice = "Repository Root"
    var environmentVariables: [EnvironmentVariableEntry] = []
    var maxConcurrentBuilds = 2
    var buildTimeoutMinutes = 60
    var terminateChildProcessesOnStop = true
    var preservePartialOutputOnCancellation = true
    var automaticallySaveLogs = true
    var preventSleepDuringBuild = true
    var defaultBehaviorAfterBuildCompletes = "Stay on Output"

    // 04 Logs & Console
    var saveLogsAutomatically = true
    var logRetentionDays = 30
    var maxLogFileSizeMB = 100
    var maxStoredLogs = 100
    var timestampFormat = "[HH:mm:ss]"
    var logEncoding = "UTF-8"
    var consoleFontName = "SF Mono"
    var consoleFontSize = 13
    var lineSpacing = 1.2
    var wordWrap = true
    var autoScrollToBottom = true
    var showLineNumbers = true
    var colorizeOutput = true
    var defaultLogFilter = "All Lines"
    var searchIsCaseSensitive = false

    // 05 Appearance
    var theme: AppTheme = .system
    var uiDensity = "Comfortable"
    var sidebarWidth = "Medium (280px)"
    var textSizePercent = 100
    var accentColorHex = "#0A84FF"
    var showAnimations = true
    var roundWindowCorners = true
    var reduceTransparency = false
    var useSystemFont = true

    // 06 Notifications
    var enableBuildNotifications = true
    var notifyBuildStarted = true
    var notifyBuildSucceeded = true
    var notifyBuildFailed = true
    var notifyBuildCancelled = true
    var notifyLongRunningBuildCompleted = true
    var notifyOnlyWhenNotInFocus = true
    var notificationSound = "Glass"
    var notificationDuration = "5 seconds"
    var groupMultipleNotifications = false

    // 07 Advanced
    var allowScriptsOutsideBuildScripts = false
    var globalBuildTimeoutMinutes = 0
    var detectExecutableFilesAutomatically = true
    var verboseDebugLogging = false
    var logInternalDiagnosticsToFile = true
    var diagnosticsLogLocation = "~/Library/Logs/LXC-BRM/"
    var gitHubRateLimitAlertThreshold = "Warn me at 20%"

    static let recommendedDefaults = Preferences()

    static func loadFromDisk() -> Preferences {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let url = appSupport.appendingPathComponent("LXC-BRM/preferences.json")
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(Preferences.self, from: data) else {
            return .recommendedDefaults
        }
        return decoded
    }

    var sidebarWidthPoints: CGFloat {
        switch sidebarWidth {
        case "Narrow (220px)": return 220
        case "Wide (340px)": return 340
        default: return 280
        }
    }
}
