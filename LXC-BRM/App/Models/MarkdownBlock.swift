import Foundation

/// One block-level element of a Markdown document.
///
/// Markdown is defined in two layers, and this is the block layer. Inline spans — bold, italic,
/// links, inline code — are deliberately left as raw text here and handed to Foundation's
/// `AttributedString(markdown:)` at render time, which is the standard Apple API for that and is
/// already correct. Writing an inline parser by hand would be duplicating it badly.
enum MarkdownBlock: Equatable, Identifiable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(language: String?, code: String)
    case listItem(ListItem)
    case quote(depth: Int, text: String)
    case table(MarkdownTable)
    case rule
    case image(alt: String, source: String)
    /// Raw HTML, shown escaped rather than executed.
    case htmlBlock(text: String)

    struct ListItem: Equatable {
        /// Indent level, 0 for top level.
        let depth: Int
        /// `nil` for a bullet, otherwise the rendered number.
        let number: Int?
        /// `nil` when this is not a task item.
        let isChecked: Bool?
        let text: String
    }

    struct MarkdownTable: Equatable {
        enum Alignment: Equatable {
            case leading, center, trailing
        }
        let headers: [String]
        let alignments: [Alignment]
        let rows: [[String]]
    }

    /// Stable within one parse, which is all `ForEach` needs.
    var id: String {
        switch self {
        case .heading(let level, let text): return "h\(level):\(text)"
        case .paragraph(let text): return "p:\(text)"
        case .codeBlock(let language, let code): return "code:\(language ?? ""):\(code.prefix(64))"
        case .listItem(let item): return "li:\(item.depth):\(item.number ?? -1):\(item.text)"
        case .quote(let depth, let text): return "q:\(depth):\(text)"
        case .table(let table): return "table:\(table.headers.joined(separator: "|"))"
        case .rule: return "rule:\(UUID().uuidString)"
        case .image(let alt, let source): return "img:\(alt):\(source)"
        case .htmlBlock(let text): return "html:\(text.prefix(64))"
        }
    }
}
