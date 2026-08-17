import Foundation

enum BuildScriptLocation: String, Codable, CaseIterable, Hashable {
    case standardFolder
    case repository
    case outsideRepository
    case missing
    case stale
    case unavailable

    var label: String {
        switch self {
        case .standardFolder: return "Standard folder"
        case .repository: return "In repository"
        case .outsideRepository: return "Outside repository"
        case .missing: return "Missing"
        case .stale: return "Stale"
        case .unavailable: return "Remote only"
        }
    }

    var isRunnable: Bool {
        switch self {
        case .standardFolder, .repository, .outsideRepository: return true
        case .missing, .stale, .unavailable: return false
        }
    }
}

enum BuildParameterKind: String, Codable, CaseIterable, Hashable {
    case text
    case number
    case boolean
    case choice
    case path
}

/// Scripts can declare inputs in leading comments, for example:
/// `# lxc:param configuration type=choice options=Debug,Release default=Debug required=true`
struct BuildParameterDefinition: Identifiable, Codable, Hashable {
    let key: String
    let label: String
    let kind: BuildParameterKind
    let options: [String]
    let isRequired: Bool
    let defaultValue: String
    let placeholder: String
    let helpText: String
    let dependsOnKey: String?
    let visibleWhenValue: String?

    var id: String { key }

    init(
        key: String,
        label: String? = nil,
        kind: BuildParameterKind = .text,
        options: [String] = [],
        isRequired: Bool = false,
        defaultValue: String = "",
        placeholder: String = "",
        helpText: String = "",
        dependsOnKey: String? = nil,
        visibleWhenValue: String? = nil
    ) {
        self.key = key
        self.label = label ?? key.replacingOccurrences(of: "-", with: " ").capitalized
        self.kind = kind
        self.options = options
        self.isRequired = isRequired
        self.defaultValue = defaultValue
        self.placeholder = placeholder
        self.helpText = helpText
        self.dependsOnKey = dependsOnKey
        self.visibleWhenValue = visibleWhenValue
    }
}

typealias BuildParameterValues = [String: String]

struct BuildInvocation: Hashable {
    let script: BuildScript
    let arguments: [String]
    let commandPreview: String
    let parameterValues: BuildParameterValues
}

enum BuildWorkspaceError: LocalizedError, Equatable {
    case validation(String)
    case discovery(String)
    case execution(String)
    case terminated(String)

    var errorDescription: String? {
        switch self {
        case .validation(let message), .discovery(let message), .execution(let message), .terminated(let message):
            return message
        }
    }
}

struct BuildScript: Identifiable, Hashable {
    let id: String
    let fileName: String
    let label: String
    let path: String
    let location: BuildScriptLocation
    let parameters: [BuildParameterDefinition]
    let isRemote: Bool

    init(
        fileName: String,
        label: String,
        path: String,
        id: String? = nil,
        location: BuildScriptLocation = .standardFolder,
        parameters: [BuildParameterDefinition] = [],
        isRemote: Bool = false
    ) {
        self.fileName = fileName
        self.label = label
        self.path = path
        self.id = id ?? BuildScriptPathResolver.canonicalIdentifier(for: path, isRemote: isRemote)
        self.location = location
        self.parameters = parameters
        self.isRemote = isRemote
    }

    /// Name of the directory containing the script. Shown in the scripts table in place of the
    /// full path, which is too long for the row and lives in the Detail View Window instead.
    var folderName: String {
        let folder = (path as NSString).deletingLastPathComponent
        let name = (folder as NSString).lastPathComponent
        return name.isEmpty ? "—" : name
    }
}

enum BuildScanResult: Equatable {
    case success(scripts: [BuildScript])
    case missingBuildFolder
    case emptyScripts
    case unreachable(String)
}
