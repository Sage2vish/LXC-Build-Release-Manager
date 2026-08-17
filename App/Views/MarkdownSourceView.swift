import SwiftUI
import AppKit

/// The Source half of the Docs tab: the file exactly as it is on disk, and — only here — an
/// editor for it.
///
/// Preview is a reader and never mutates anything. Editing has to be entered deliberately from
/// Source, because writing into a file in the user's repository is destructive if it happens by
/// accident.
struct MarkdownSourceView: View {
    let text: String
    let isEditing: Bool
    @Binding var draft: String

    var body: some View {
        if isEditing {
            TextEditor(text: $draft)
                .font(.system(.callout, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(.background)
                .padding(8)
                .accessibilityLabel("Markdown source editor")
        } else {
            ScrollView([.vertical, .horizontal]) {
                HStack(alignment: .top, spacing: 0) {
                    // A real gutter: its own surface, right-aligned dimmer numbers, and a rule
                    // separating it from the text — the way an editor shows it.
                    Text(lineNumbers)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 44, alignment: .trailing)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                        .accessibilityHidden(true)

                    Rectangle()
                        .fill(Color(nsColor: .separatorColor))
                        .frame(width: 1)

                    Text(text)
                        .font(.system(.callout, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .accessibilityLabel("Markdown source")
        }
    }

    private var lineNumbers: String {
        let count = max(1, text.components(separatedBy: .newlines).count)
        return (1...count).map(String.init).joined(separator: "\n")
    }
}

/// Reading and writing a document, with the checks that keep an edit from destroying work.
enum MarkdownDocumentStore {
    enum SaveResult: Equatable {
        case saved
        case changedOnDisk
        case failed(String)
    }

    /// Modification date at load time, used to detect a change made elsewhere.
    static func modificationDate(of path: String, fileManager: FileManager = .default) -> Date? {
        (try? fileManager.attributesOfItem(atPath: path))?[.modificationDate] as? Date
    }

    static func read(path: String) -> String? {
        try? String(contentsOfFile: path, encoding: .utf8)
    }

    /// Writes atomically, refusing when the file changed after it was loaded.
    ///
    /// Silently overwriting there would throw away whatever the other writer did — and in this
    /// app the "other writer" is frequently the user's editor or another agent.
    static func save(
        _ contents: String,
        to path: String,
        loadedAt: Date?,
        fileManager: FileManager = .default
    ) -> SaveResult {
        if let loadedAt, let current = modificationDate(of: path, fileManager: fileManager) {
            // A whole second of slack: filesystem timestamps are not infinitely precise.
            if current.timeIntervalSince(loadedAt) > 1 {
                return .changedOnDisk
            }
        }
        do {
            try contents.write(toFile: path, atomically: true, encoding: .utf8)
            return .saved
        } catch {
            return .failed(error.localizedDescription)
        }
    }
}
