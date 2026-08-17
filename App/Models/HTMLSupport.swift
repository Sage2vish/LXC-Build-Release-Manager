import Foundation

/// Parsing and safety rules for the HTML that appears inside Markdown files.
///
/// Markdown cannot centre an image or force a line break, so documents reach for HTML. GitHub
/// renders a whitelist of tags and strips everything else; that is the model here. Anything not
/// explicitly allowed is never rendered as markup, and nothing may execute or fetch.
enum HTMLSupport {
    /// Tags rendered as real elements.
    static let allowedTags: Set<String> = [
        "img", "br", "hr", "p", "div", "span", "center",
        "a", "b", "strong", "i", "em", "code", "kbd",
        "sub", "sup", "del", "s", "mark",
        "h1", "h2", "h3", "h4", "h5", "h6",
        "ul", "ol", "li", "blockquote",
        "table", "thead", "tbody", "tr", "td", "th",
        "details", "summary"
    ]

    /// Tags that must never render, and whose content is shown escaped instead.
    ///
    /// A Markdown file is untrusted input: it comes from a repository the user opened, not from
    /// us. None of these may run, load, or navigate anything.
    static let deniedTags: Set<String> = [
        "script", "iframe", "style", "object", "embed", "link", "meta",
        "form", "input", "button", "select", "textarea",
        "svg", "video", "audio", "applet", "base", "frame", "frameset"
    ]

    /// A parsed opening tag.
    struct Tag: Equatable {
        let name: String
        let attributes: [String: String]
        /// `<br/>` and void elements like `<img>` have no closing tag.
        let isSelfClosing: Bool
    }

    /// Elements that never have closing tags.
    static let voidTags: Set<String> = ["img", "br", "hr", "input", "meta", "link"]

    static func isAllowed(_ name: String) -> Bool {
        allowedTags.contains(name.lowercased())
    }

    static func isDenied(_ name: String) -> Bool {
        deniedTags.contains(name.lowercased())
    }

    /// Parses the first tag in `text`, if it starts with one.
    ///
    /// Deliberately small: this handles the attribute forms that appear in real documents
    /// (`key="value"`, `key='value'`, bare `key`) and does not attempt to be a general HTML
    /// parser, which would be a liability rather than a feature.
    static func parseTag(_ text: String) -> Tag? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("<"), let close = trimmed.firstIndex(of: ">") else { return nil }

        var body = String(trimmed[trimmed.index(after: trimmed.startIndex)..<close])
        guard !body.hasPrefix("/"), !body.hasPrefix("!") else { return nil }

        var selfClosing = false
        if body.hasSuffix("/") {
            selfClosing = true
            body.removeLast()
        }

        let scanner = Scanner(string: body)
        scanner.charactersToBeSkipped = .whitespacesAndNewlines
        guard let rawName = scanner.scanCharacters(from: CharacterSet.alphanumerics) else { return nil }
        let name = rawName.lowercased()

        var attributes: [String: String] = [:]
        while !scanner.isAtEnd {
            guard let key = scanner.scanUpToString("=")?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased(), !key.isEmpty else { break }
            guard scanner.scanString("=") != nil else { break }

            var value: String?
            if scanner.scanString("\"") != nil {
                value = scanner.scanUpToString("\"")
                _ = scanner.scanString("\"")
            } else if scanner.scanString("'") != nil {
                value = scanner.scanUpToString("'")
                _ = scanner.scanString("'")
            } else {
                value = scanner.scanUpToCharacters(from: .whitespaces)
            }

            // Event handlers are dropped outright — a document must not be able to run anything.
            if key.hasPrefix("on") { continue }
            if let value { attributes[key] = value }
        }

        return Tag(
            name: name,
            attributes: attributes,
            isSelfClosing: selfClosing || voidTags.contains(name)
        )
    }

    /// True when a URL is safe to hand to the system.
    ///
    /// `javascript:` and `data:` are the two schemes that turn a link into code execution, so
    /// they are refused wherever they appear.
    static func isSafeURL(_ raw: String) -> Bool {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if value.hasPrefix("javascript:") || value.hasPrefix("data:") || value.hasPrefix("vbscript:") {
            return false
        }
        return true
    }

    /// Extracts the content between `<tag …>` and `</tag>`, when both are on the same line.
    static func innerText(of name: String, in text: String) -> String? {
        guard let openEnd = text.range(of: ">"),
              let closeStart = text.range(of: "</\(name)", options: .caseInsensitive) else { return nil }
        guard openEnd.upperBound <= closeStart.lowerBound else { return nil }
        return String(text[openEnd.upperBound..<closeStart.lowerBound])
    }

    /// Rewrites the inline HTML inside a run of text into the Markdown that means the same
    /// thing, so `AttributedString` can style it. Denied tags are escaped rather than converted.
    ///
    /// Anything not recognised is left exactly as it was — that keeps `<repository>` and
    /// `<tabname>`, which appear as placeholders in this project's own docs, as visible text
    /// instead of silently disappearing.
    static func convertInlineHTML(_ text: String) -> String {
        var result = text

        // Denied tags first: strip the element and its content entirely so nothing leaks through.
        for tag in deniedTags {
            result = removeElement(tag, from: result)
        }

        let simple: [(tags: [String], markdown: String)] = [
            (["strong", "b"], "**"),
            (["em", "i"], "*"),
            (["code", "kbd"], "`"),
            (["del", "s"], "~~")
        ]
        for entry in simple {
            for tag in entry.tags {
                result = result.replacingOccurrences(
                    of: "<\(tag)\\s*[^>]*>(.*?)</\(tag)>",
                    with: "\(entry.markdown)$1\(entry.markdown)",
                    options: [.regularExpression, .caseInsensitive]
                )
            }
        }

        // Links become Markdown links, but only when the destination is safe.
        result = replaceAnchors(in: result)

        // Tags that carry no inline styling we can express: keep the text, drop the wrapper.
        for tag in ["span", "sub", "sup", "mark", "p", "div", "center", "summary"] {
            result = result.replacingOccurrences(
                of: "</?\(tag)\\s*[^>]*>",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        return result.trimmingCharacters(in: .whitespaces)
    }

    /// Removes an element and everything inside it.
    private static func removeElement(_ tag: String, from text: String) -> String {
        var result = text.replacingOccurrences(
            of: "<\(tag)\\s*[^>]*>.*?</\(tag)>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        // An unclosed denied tag still must not survive.
        result = result.replacingOccurrences(
            of: "</?\(tag)\\s*[^>]*>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        return result
    }

    private static func replaceAnchors(in text: String) -> String {
        guard let regex = try? NSRegularExpression(
            pattern: "<a\\s+[^>]*href\\s*=\\s*[\"']([^\"']+)[\"'][^>]*>(.*?)</a>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return text }

        var result = text
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed()
        for match in matches {
            guard let full = Range(match.range, in: text),
                  let hrefRange = Range(match.range(at: 1), in: text),
                  let labelRange = Range(match.range(at: 2), in: text) else { continue }
            let href = String(text[hrefRange])
            let label = String(text[labelRange])
            // An unsafe destination keeps its label but loses the link.
            let replacement = isSafeURL(href) ? "[\(label)](\(href))" : label
            result = result.replacingOccurrences(of: String(text[full]), with: replacement)
        }
        return result
    }
}
