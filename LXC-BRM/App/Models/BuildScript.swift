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

enum BuildCommandBuilder {
    static func invocation(for script: BuildScript, values: BuildParameterValues) throws -> BuildInvocation {
        let validationErrors = validate(script: script, values: values)
        guard validationErrors.isEmpty else {
            throw BuildWorkspaceError.validation(validationErrors.joined(separator: "\n"))
        }

        var arguments: [String] = []
        for parameter in activeParameters(for: script, values: values) {
            let value = value(for: parameter, values: values)
            guard !value.isEmpty || parameter.kind == .boolean else { continue }

            switch parameter.kind {
            case .boolean:
                if value == "true" {
                    arguments.append("--\(parameter.key)")
                }
            case .text, .number, .choice, .path:
                arguments.append("--\(parameter.key)")
                arguments.append(value)
            }
        }

        let commandPreview = ([script.path] + arguments)
            .map(shellEscaped)
            .joined(separator: " ")
        return BuildInvocation(script: script, arguments: arguments, commandPreview: commandPreview, parameterValues: values)
    }

    static func validate(script: BuildScript, values: BuildParameterValues) -> [String] {
        activeParameters(for: script, values: values).compactMap { parameter in
            let value = value(for: parameter, values: values)
            if parameter.isRequired && value.isEmpty {
                return "\(parameter.label) is required."
            }

            guard !value.isEmpty else { return nil }
            switch parameter.kind {
            case .number where Double(value) == nil:
                return "\(parameter.label) must be a number."
            case .choice where !parameter.options.contains(value):
                return "Choose a valid value for \(parameter.label)."
            case .path where !FileManager.default.fileExists(atPath: value):
                return "The path for \(parameter.label) does not exist."
            case .boolean where value != "true" && value != "false":
                return "\(parameter.label) must be on or off."
            default:
                return nil
            }
        }
    }

    private static func value(for parameter: BuildParameterDefinition, values: BuildParameterValues) -> String {
        (values[parameter.key] ?? parameter.defaultValue).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func activeParameters(for script: BuildScript, values: BuildParameterValues) -> [BuildParameterDefinition] {
        script.parameters.filter { parameter in
            guard let dependsOnKey = parameter.dependsOnKey else { return true }
            let expectedValue = parameter.visibleWhenValue ?? "true"
            return (values[dependsOnKey] ?? "") == expectedValue
        }
    }

    private static func shellEscaped(_ argument: String) -> String {
        guard argument.contains(where: { $0.isWhitespace || $0 == "'" || $0 == "\"" }) else { return argument }
        return "'\(argument.replacingOccurrences(of: "'", with: "'\\\"'\\\"'"))'"
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
}

enum BuildScanResult: Equatable {
    case success(scripts: [BuildScript])
    case missingBuildFolder
    case emptyScripts
    case unreachable(String)
}
