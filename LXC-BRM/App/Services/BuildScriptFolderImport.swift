import Foundation

/// Decides what happens when the user picks a folder to import build scripts from.
///
/// This lives outside the view so every branch — outside-repository, unreadable, empty, and
/// all-already-added — can be tested directly. Driving them through the real `NSOpenPanel`
/// requires GUI automation that cannot reliably reach the failure cases.
enum BuildScriptFolderImport {
    enum Outcome: Equatable {
        /// Scripts that are new to this repository, in stable sorted order.
        case scripts([String])
        case outsideRepository
        case unreadableFolder
        case noScriptsInFolder
        case allAlreadyAdded

        var errorMessage: String? {
            switch self {
            case .scripts: return nil
            case .outsideRepository:
                return "That folder is outside this repository. Enable that option in Preferences to add it."
            case .unreadableFolder:
                return "That folder could not be read."
            case .noScriptsInFolder:
                return "No .sh scripts were found in that folder."
            case .allAlreadyAdded:
                return "Those scripts are already in this repository."
            }
        }
    }

    static func resolve(
        folderPath: String,
        repositoryPath: String,
        allowOutsideRepository: Bool,
        existingPaths: Set<String>,
        fileManager: FileManager = .default
    ) -> Outcome {
        guard allowOutsideRepository
                || BuildScriptPathResolver.isWithin(folderPath, rootPath: repositoryPath) else {
            return .outsideRepository
        }

        guard let entries = try? fileManager.contentsOfDirectory(atPath: folderPath) else {
            return .unreadableFolder
        }

        let scriptPaths = entries
            .filter { $0.hasSuffix(".sh") }
            .map { (folderPath as NSString).appendingPathComponent($0) }
            .sorted()

        guard !scriptPaths.isEmpty else { return .noScriptsInFolder }

        let newPaths = scriptPaths.filter { !existingPaths.contains($0) }
        guard !newPaths.isEmpty else { return .allAlreadyAdded }

        return .scripts(newPaths)
    }
}
