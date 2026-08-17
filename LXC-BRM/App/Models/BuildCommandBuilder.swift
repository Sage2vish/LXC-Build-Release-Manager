import Foundation

/// Turns a script plus the user's parameter values into a validated invocation.
///
/// Split out of `BuildScript.swift` so the domain data and the rules that act on it are
/// separately readable, and so command construction has one home rather than being reachable
/// from a model file.
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
