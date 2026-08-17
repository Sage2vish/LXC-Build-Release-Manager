import Foundation

/// Turns Markdown source into block elements.
///
/// Pure: a `String` in, `[MarkdownBlock]` out, no I/O and no view types, so every rule below is
/// testable directly. Handles the GitHub Flavored Markdown subset that actually appears in this
/// project's files — see `Plan-MarkdownExplorer-todo.md` for the target table.
enum MarkdownParser {
    static func parse(_ source: String) -> [MarkdownBlock] {
        var lines = source.components(separatedBy: .newlines)
        stripFrontMatter(&lines)

        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var index = 0

        func flushParagraph() {
            let text = paragraph.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            paragraph.removeAll()
            guard !text.isEmpty else { return }
            // A paragraph that is nothing but an image becomes an image block, which is how
            // README badges and diagrams are almost always written.
            if let image = standaloneImage(in: text) {
                blocks.append(image)
            } else {
                blocks.append(.paragraph(text: text))
            }
        }

        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Fenced code. Everything until the closing fence is literal.
            if let fence = fenceMarker(trimmed) {
                flushParagraph()
                let language = String(trimmed.dropFirst(fence.count)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                index += 1
                var closed = false
                while index < lines.count {
                    let candidate = lines[index].trimmingCharacters(in: .whitespaces)
                    if candidate.hasPrefix(fence) {
                        closed = true
                        index += 1
                        break
                    }
                    code.append(lines[index])
                    index += 1
                }
                _ = closed // An unterminated fence still keeps its content rather than dropping it.
                blocks.append(.codeBlock(
                    language: language.isEmpty ? nil : language,
                    code: code.joined(separator: "\n")
                ))
                continue
            }

            if trimmed.isEmpty {
                flushParagraph()
                index += 1
                continue
            }

            // Setext heading: text underlined by === or ---. Must be checked before the
            // horizontal rule, or every underlined heading becomes a rule.
            if !paragraph.isEmpty, isSetextUnderline(trimmed) {
                let text = paragraph.joined(separator: " ").trimmingCharacters(in: .whitespaces)
                paragraph.removeAll()
                blocks.append(.heading(level: trimmed.hasPrefix("=") ? 1 : 2, text: text))
                index += 1
                continue
            }

            if isHorizontalRule(trimmed) {
                flushParagraph()
                blocks.append(.rule)
                index += 1
                continue
            }

            if let heading = atxHeading(trimmed) {
                flushParagraph()
                blocks.append(heading)
                index += 1
                continue
            }

            if let quote = quoteLine(trimmed) {
                flushParagraph()
                blocks.append(quote)
                index += 1
                continue
            }

            // A table needs its delimiter row on the following line.
            if trimmed.contains("|"), index + 1 < lines.count,
               let table = parseTable(lines: lines, startingAt: index) {
                flushParagraph()
                blocks.append(.table(table.table))
                index = table.nextIndex
                continue
            }

            if let item = listItem(line) {
                flushParagraph()
                blocks.append(.listItem(item))
                index += 1
                continue
            }

            // Indented code, but only when it does not continue a paragraph.
            if paragraph.isEmpty, isIndentedCode(line) {
                var code: [String] = []
                while index < lines.count, isIndentedCode(lines[index]) || lines[index].trimmingCharacters(in: .whitespaces).isEmpty {
                    if lines[index].trimmingCharacters(in: .whitespaces).isEmpty,
                       !(index + 1 < lines.count && isIndentedCode(lines[index + 1])) {
                        break
                    }
                    code.append(String(lines[index].dropFirst(min(4, lines[index].prefix(4).count))))
                    index += 1
                }
                blocks.append(.codeBlock(language: nil, code: code.joined(separator: "\n")))
                continue
            }

            if isHTMLBlock(trimmed) {
                flushParagraph()
                blocks.append(.htmlBlock(text: trimmed))
                index += 1
                continue
            }

            paragraph.append(trimmed)
            index += 1
        }

        flushParagraph()
        return blocks
    }

    // MARK: Line rules

    /// YAML front matter at the very top is metadata, not content.
    private static func stripFrontMatter(_ lines: inout [String]) {
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else { return }
        for index in 1..<lines.count where lines[index].trimmingCharacters(in: .whitespaces) == "---" {
            lines.removeSubrange(0...index)
            return
        }
    }

    /// Returns the fence marker (``` or ~~~) when the line opens a fence.
    private static func fenceMarker(_ trimmed: String) -> String? {
        for marker in ["```", "~~~"] where trimmed.hasPrefix(marker) {
            return marker
        }
        return nil
    }

    private static func atxHeading(_ trimmed: String) -> MarkdownBlock? {
        guard trimmed.hasPrefix("#") else { return nil }
        let hashes = trimmed.prefix { $0 == "#" }
        let level = hashes.count
        guard (1...6).contains(level) else { return nil }
        let rest = trimmed.dropFirst(level)
        // `#hashtag` is not a heading — a space is required.
        guard rest.first == " " else { return nil }
        var text = rest.trimmingCharacters(in: .whitespaces)
        // Closing hashes are decoration.
        while text.hasSuffix("#") { text.removeLast() }
        return .heading(level: level, text: text.trimmingCharacters(in: .whitespaces))
    }

    private static func isSetextUnderline(_ trimmed: String) -> Bool {
        guard trimmed.count >= 2 else { return false }
        return trimmed.allSatisfy { $0 == "=" } || trimmed.allSatisfy { $0 == "-" }
    }

    private static func isHorizontalRule(_ trimmed: String) -> Bool {
        let stripped = trimmed.replacingOccurrences(of: " ", with: "")
        guard stripped.count >= 3 else { return false }
        return stripped.allSatisfy { $0 == "-" }
            || stripped.allSatisfy { $0 == "*" }
            || stripped.allSatisfy { $0 == "_" }
    }

    private static func quoteLine(_ trimmed: String) -> MarkdownBlock? {
        guard trimmed.hasPrefix(">") else { return nil }
        var depth = 0
        var rest = Substring(trimmed)
        while rest.hasPrefix(">") {
            depth += 1
            rest = rest.dropFirst()
            if rest.hasPrefix(" ") { rest = rest.dropFirst() }
        }
        return .quote(depth: depth, text: String(rest).trimmingCharacters(in: .whitespaces))
    }

    private static func listItem(_ line: String) -> MarkdownBlock.ListItem? {
        let leading = line.prefix { $0 == " " || $0 == "\t" }
        // Tabs count as four columns, matching how the files are actually written.
        let width = leading.reduce(0) { $0 + ($1 == "\t" ? 4 : 1) }
        let depth = width / 2
        let trimmed = line.trimmingCharacters(in: .whitespaces)

        var number: Int?
        var content: String

        if let marker = trimmed.first, "-*+".contains(marker), trimmed.dropFirst().hasPrefix(" ") {
            content = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
        } else if let dot = trimmed.firstIndex(of: "."),
                  let value = Int(trimmed[trimmed.startIndex..<dot]),
                  trimmed[dot...].dropFirst().hasPrefix(" ") {
            number = value
            content = String(trimmed[dot...].dropFirst()).trimmingCharacters(in: .whitespaces)
        } else {
            return nil
        }

        var isChecked: Bool?
        let lowered = content.lowercased()
        if lowered.hasPrefix("[ ] ") || lowered == "[ ]" {
            isChecked = false
            content = String(content.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        } else if lowered.hasPrefix("[x] ") || lowered == "[x]" {
            isChecked = true
            content = String(content.dropFirst(3)).trimmingCharacters(in: .whitespaces)
        }

        return MarkdownBlock.ListItem(depth: depth, number: number, isChecked: isChecked, text: content)
    }

    private static func isIndentedCode(_ line: String) -> Bool {
        line.hasPrefix("    ") || line.hasPrefix("\t")
    }

    private static func isHTMLBlock(_ trimmed: String) -> Bool {
        trimmed.hasPrefix("<") && trimmed.hasSuffix(">") && !trimmed.hasPrefix("<http")
    }

    /// `![alt](src)` alone on a line.
    private static func standaloneImage(in text: String) -> MarkdownBlock? {
        guard text.hasPrefix("!["), text.hasSuffix(")"),
              let altEnd = text.firstIndex(of: "]"),
              let parenStart = text.firstIndex(of: "("),
              parenStart > altEnd else { return nil }
        let alt = String(text[text.index(text.startIndex, offsetBy: 2)..<altEnd])
        let source = String(text[text.index(after: parenStart)..<text.index(before: text.endIndex)])
        // Only when there is nothing else on the line.
        guard !source.contains("]("), !alt.contains("![") else { return nil }
        return .image(alt: alt, source: source)
    }

    // MARK: Tables

    private static func parseTable(
        lines: [String],
        startingAt start: Int
    ) -> (table: MarkdownBlock.MarkdownTable, nextIndex: Int)? {
        let headerLine = lines[start].trimmingCharacters(in: .whitespaces)
        let delimiterLine = lines[start + 1].trimmingCharacters(in: .whitespaces)
        guard headerLine.contains("|"), isDelimiterRow(delimiterLine) else { return nil }

        let headers = splitRow(headerLine)
        let alignments = splitRow(delimiterLine).map { cell -> MarkdownBlock.MarkdownTable.Alignment in
            let starts = cell.hasPrefix(":")
            let ends = cell.hasSuffix(":")
            if starts && ends { return .center }
            if ends { return .trailing }
            return .leading
        }

        var rows: [[String]] = []
        var index = start + 2
        while index < lines.count {
            let row = lines[index].trimmingCharacters(in: .whitespaces)
            guard row.contains("|"), !row.isEmpty else { break }
            var cells = splitRow(row)
            // Ragged rows are padded or trimmed rather than rejected.
            while cells.count < headers.count { cells.append("") }
            if cells.count > headers.count { cells = Array(cells.prefix(headers.count)) }
            rows.append(cells)
            index += 1
        }

        return (
            MarkdownBlock.MarkdownTable(headers: headers, alignments: alignments, rows: rows),
            index
        )
    }

    private static func isDelimiterRow(_ line: String) -> Bool {
        let cells = splitRow(line)
        guard !cells.isEmpty else { return false }
        return cells.allSatisfy { cell in
            let stripped = cell.replacingOccurrences(of: ":", with: "")
            return !stripped.isEmpty && stripped.allSatisfy { $0 == "-" }
        }
    }

    private static func splitRow(_ line: String) -> [String] {
        var text = line
        if text.hasPrefix("|") { text.removeFirst() }
        if text.hasSuffix("|") { text.removeLast() }
        return text.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
