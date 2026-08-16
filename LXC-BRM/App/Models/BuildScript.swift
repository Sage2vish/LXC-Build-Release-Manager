import Foundation

struct BuildScript: Identifiable, Hashable {
    var id: String { fileName }
    let fileName: String
    let label: String
    let path: String
}

enum BuildScanResult: Equatable {
    case success(scripts: [BuildScript])
    case missingBuildFolder
    case emptyScripts
    case unreachable(String)
}
