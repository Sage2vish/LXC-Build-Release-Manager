import SwiftUI
import AppKit

/// Renders parsed Markdown blocks as native SwiftUI.
///
/// Block structure is drawn here; inline spans (bold, italic, links, inline code) go through
/// `AttributedString(markdown:)`, which is Foundation's own inline parser. That split is why this
/// needs no third-party package and still gets emphasis and links right.
struct MarkdownRenderedView: View {
    let blocks: [MarkdownBlock]
    /// Folder of the document, used to resolve relative image and link paths.
    let baseURL: URL?

    /// Scaling from the app's text-size preference.
    @Environment(\.appTextScale) private var textScale

    var body: some View {
        VStack(alignment: .leading, spacing: 14 * textScale) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                view(for: block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
        // Relative links in a document are relative to that document's folder, not to the app.
        // Foundation hands us the raw destination, so resolve it here and refuse anything
        // that is not a file or an http(s) URL.
        .environment(\.openURL, OpenURLAction { url in
            guard let resolved = resolveLink(url) else { return .discarded }
            NSWorkspace.shared.open(resolved)
            return .handled
        })
    }

    /// Turns a link destination into something safe to open.
    ///
    /// A bare `docs/guide.md` arrives as a relative URL with no scheme; without this it simply
    /// fails to open. Anything that is not file/http/https is refused rather than handed to the
    /// system.
    private func resolveLink(_ url: URL) -> URL? {
        if let scheme = url.scheme?.lowercased() {
            guard ["http", "https", "file"].contains(scheme) else { return nil }
            return url
        }
        guard let baseURL else { return nil }
        let candidate = baseURL.appendingPathComponent(url.relativePath).standardizedFileURL
        return FileManager.default.fileExists(atPath: candidate.path) ? candidate : nil
    }

    @ViewBuilder
    private func view(for block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            headingView(level: level, text: text)

        case .paragraph(let text):
            inlineText(text)
                .fixedSize(horizontal: false, vertical: true)

        case .codeBlock(let language, let code):
            CodeBlockView(language: language, code: code)

        case .listItem(let item):
            listItemView(item)

        case .quote(let depth, let text):
            HStack(alignment: .top, spacing: 10) {
                Rectangle()
                    .fill(.tint.opacity(0.5))
                    .frame(width: 3)
                inlineText(text)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, CGFloat(max(0, depth - 1)) * 16)

        case .table(let table):
            MarkdownTableView(table: table)

        case .rule:
            Divider().padding(.vertical, 4)

        case .image(let alt, let source):
            imageView(alt: alt, source: source)

        case .htmlImage(let alt, let source, let width, let alignment):
            HStack {
                if alignment != .leading { Spacer(minLength: 0) }
                imageView(alt: alt, source: source, width: width)
                if alignment != .trailing { Spacer(minLength: 0) }
            }

        case .lineBreak:
            // <br> is an explicit blank line; Markdown has no syntax for one.
            Spacer().frame(height: 8)

        case .aligned(let alignment, let inner):
            HStack {
                if alignment != .leading { Spacer(minLength: 0) }
                // Recursing through the concrete view type rather than calling `view(for:)`
                // again: a `some View` function that returns itself is self-referential and
                // will not compile.
                MarkdownRenderedView(blocks: inner, baseURL: baseURL)
                if alignment != .trailing { Spacer(minLength: 0) }
            }

        case .disclosure(let summary, let inner):
            DisclosureGroup {
                MarkdownRenderedView(blocks: inner, baseURL: baseURL)
                    .padding(.top, 6)
            } label: {
                inlineText(summary).font(.callout.weight(.semibold))
            }

        case .htmlBlock(let text):
            // Shown escaped. Never executed — a document on disk must not be able to run
            // anything or reach the network.
            Text(text)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: Blocks

    @ViewBuilder
    private func headingView(level: Int, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            inlineText(text)
                .font(headingFont(level))
                .fixedSize(horizontal: false, vertical: true)
            // GitHub underlines H1 and H2.
            if level <= 2 {
                Divider()
            }
        }
        .padding(.top, level <= 2 ? 10 : 6)
    }

    private func headingFont(_ level: Int) -> Font {
        let base: CGFloat
        let weight: Font.Weight
        switch level {
        case 1: base = 28; weight = .bold
        case 2: base = 22; weight = .bold
        case 3: base = 18; weight = .semibold
        case 4: base = 16; weight = .semibold
        case 5: base = 14; weight = .semibold
        default: base = 13; weight = .semibold
        }
        return .system(size: base * textScale, weight: weight)
    }

    @ViewBuilder
    private func listItemView(_ item: MarkdownBlock.ListItem) -> some View {
        HStack(alignment: .top, spacing: 8) {
            marker(for: item)
                .frame(minWidth: 18, alignment: .trailing)
            inlineText(item.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, CGFloat(item.depth) * 18)
    }

    @ViewBuilder
    private func marker(for item: MarkdownBlock.ListItem) -> some View {
        if let isChecked = item.isChecked {
            Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                .foregroundStyle(isChecked ? Color.accentColor : .secondary)
                .accessibilityLabel(isChecked ? "Completed" : "Not completed")
        } else if let number = item.number {
            Text("\(number).")
                .foregroundStyle(.secondary)
                .monospacedDigit()
        } else {
            Text("•").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func imageView(alt: String, source: String, width: Double? = nil) -> some View {
        if let url = resolvedImageURL(source), let image = NSImage(contentsOf: url) {
            VStack(alignment: .leading, spacing: 4) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    // An HTML width attribute is respected, but never beyond the column.
                    .frame(maxWidth: width.map { CGFloat($0) } ?? .infinity, alignment: .leading)
                    .accessibilityLabel(alt.isEmpty ? "Image" : alt)
                if !alt.isEmpty {
                    Text(alt).font(.caption).foregroundStyle(.secondary)
                }
            }
        } else {
            // Remote images are deliberately not fetched, and a missing local file says so
            // rather than rendering nothing.
            Label(
                alt.isEmpty ? "Image not shown: \(source)" : "\(alt) — not shown",
                systemImage: isRemote(source) ? "network.slash" : "photo"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 6))
        }
    }

    private func isRemote(_ source: String) -> Bool {
        source.hasPrefix("http://") || source.hasPrefix("https://")
    }

    /// Local images only, resolved against the document's folder.
    private func resolvedImageURL(_ source: String) -> URL? {
        guard !isRemote(source) else { return nil }
        if source.hasPrefix("/") { return URL(fileURLWithPath: source) }
        guard let baseURL else { return nil }
        return baseURL.appendingPathComponent(source).standardizedFileURL
    }

    // MARK: Inline

    /// Inline spans via Foundation's Markdown support.
    ///
    /// `.inlineOnlyPreservingWhitespace` is the mode that behaves: full-document parsing collapses
    /// block structure, which is exactly what this renderer already handled itself.
    private func inlineText(_ text: String) -> Text {
        guard let attributed = try? AttributedString(
            markdown: text,
            options: .init(
                allowsExtendedAttributes: true,
                interpretedSyntax: .inlineOnlyPreservingWhitespace,
                failurePolicy: .returnPartiallyParsedIfPossible
            )
        ) else {
            // Malformed inline markup degrades to plain text rather than vanishing.
            return Text(text)
        }
        return Text(attributed)
    }
}

/// A fenced or indented code block: monospaced, filled, and horizontally scrollable so a long
/// line cannot stretch the document.
private struct CodeBlockView: View {
    let language: String?
    let code: String
    @State private var didCopy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if let language, !language.isEmpty {
                    Text(language)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    didCopy = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { didCopy = false }
                } label: {
                    Label(didCopy ? "Copied" : "Copy", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                        .font(.caption2)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Copy code block")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)

            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(.callout, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(.quaternary, lineWidth: 1)
        )
    }
}

/// A GFM table, with per-column alignment and horizontal scrolling.
private struct MarkdownTableView: View {
    let table: MarkdownBlock.MarkdownTable

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                row(table.headers, isHeader: true)
                Divider()
                ForEach(Array(table.rows.enumerated()), id: \.offset) { index, cells in
                    row(cells, isHeader: false)
                    if index < table.rows.count - 1 { Divider().opacity(0.4) }
                }
            }
            .background(.quaternary.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary, lineWidth: 1))
        }
    }

    private func row(_ cells: [String], isHeader: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(cells.enumerated()), id: \.offset) { index, cell in
                Text(cell)
                    .font(isHeader ? .callout.weight(.semibold) : .callout)
                    .frame(minWidth: 90, alignment: alignment(at: index))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity, alignment: alignment(at: index))
            }
        }
    }

    private func alignment(at index: Int) -> Alignment {
        guard index < table.alignments.count else { return .leading }
        switch table.alignments[index] {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}
