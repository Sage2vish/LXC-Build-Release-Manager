import Foundation
import XCTest
@testable import LXC_BRM

/// Covers the Markdown block parser and the document tree behind the Docs tab.
final class MarkdownTests: XCTestCase {
    private var temporaryDirectory: URL!

    override func setUpWithError() throws {
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("LXC-BRM-Markdown-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
    }

    // MARK: Headings

    func testHeadingLevelsAndTheThingsThatLookLikeHeadingsButAreNot() {
        let blocks = MarkdownParser.parse("""
        # One
        ## Two
        ### Three
        #### Four
        ##### Five
        ###### Six
        ####### Seven is not a heading
        #hashtag
        ## Closing hashes ##
        """)

        XCTAssertEqual(blocks[0], .heading(level: 1, text: "One"))
        XCTAssertEqual(blocks[1], .heading(level: 2, text: "Two"))
        XCTAssertEqual(blocks[2], .heading(level: 3, text: "Three"))
        XCTAssertEqual(blocks[3], .heading(level: 4, text: "Four"))
        XCTAssertEqual(blocks[4], .heading(level: 5, text: "Five"))
        XCTAssertEqual(blocks[5], .heading(level: 6, text: "Six"))
        // Seven hashes is not a heading, and neither is a hashtag with no space.
        XCTAssertTrue(blocks.contains(.paragraph(text: "####### Seven is not a heading #hashtag")))
        XCTAssertTrue(blocks.contains(.heading(level: 2, text: "Closing hashes")))
    }

    func testSetextHeadingsAreNotMistakenForHorizontalRules() {
        let blocks = MarkdownParser.parse("""
        Title Here
        ==========

        Subtitle Here
        -------------

        ---
        """)
        XCTAssertEqual(blocks[0], .heading(level: 1, text: "Title Here"))
        XCTAssertEqual(blocks[1], .heading(level: 2, text: "Subtitle Here"))
        // A bare --- with no paragraph above it really is a rule.
        XCTAssertEqual(blocks[2], .rule)
    }

    // MARK: Code

    func testFencedCodeCapturesLanguageAndKeepsContentLiteral() {
        let blocks = MarkdownParser.parse("""
        ```swift
        let x = 1
        # not a heading inside a fence
        - not a list either
        ```
        """)
        XCTAssertEqual(blocks.count, 1)
        guard case .codeBlock(let language, let code) = blocks[0] else {
            return XCTFail("Expected a code block, got \(blocks[0])")
        }
        XCTAssertEqual(language, "swift")
        XCTAssertTrue(code.contains("# not a heading inside a fence"))
        XCTAssertTrue(code.contains("- not a list either"))
    }

    func testUnterminatedFenceKeepsItsContentInsteadOfDroppingIt() {
        let blocks = MarkdownParser.parse("""
        ```
        first line
        second line
        """)
        guard case .codeBlock(let language, let code) = blocks[0] else {
            return XCTFail("Expected a code block")
        }
        XCTAssertNil(language)
        XCTAssertTrue(code.contains("first line"))
        XCTAssertTrue(code.contains("second line"))
    }

    // MARK: Lists

    func testListsCoverBulletsOrderingNestingAndTasks() {
        let blocks = MarkdownParser.parse("""
        - top level
          - nested once
        * asterisk bullet
        + plus bullet
        3. starts at three
        4. and continues
        - [ ] unchecked task
        - [x] checked task
        """)

        let items: [MarkdownBlock.ListItem] = blocks.compactMap {
            if case .listItem(let item) = $0 { return item }
            return nil
        }
        XCTAssertEqual(items.count, 8)
        XCTAssertEqual(items[0].depth, 0)
        XCTAssertEqual(items[0].text, "top level")
        XCTAssertEqual(items[1].depth, 1, "Two spaces of indent is one nesting level")
        XCTAssertNil(items[2].number, "An asterisk is a bullet")
        XCTAssertNil(items[3].number, "A plus is a bullet")
        XCTAssertEqual(items[4].number, 3, "An ordered list must keep its start value")
        XCTAssertEqual(items[5].number, 4)
        XCTAssertEqual(items[6].isChecked, false)
        XCTAssertEqual(items[6].text, "unchecked task")
        XCTAssertEqual(items[7].isChecked, true)
        XCTAssertEqual(items[7].text, "checked task")
    }

    // MARK: Tables

    func testTableParsesAlignmentsAndToleratesRaggedRows() {
        let blocks = MarkdownParser.parse("""
        | Left | Center | Right |
        | --- | :---: | ---: |
        | a | b | c |
        | only one |
        """)
        guard case .table(let table) = blocks[0] else {
            return XCTFail("Expected a table, got \(blocks[0])")
        }
        XCTAssertEqual(table.headers, ["Left", "Center", "Right"])
        XCTAssertEqual(table.alignments, [.leading, .center, .trailing])
        XCTAssertEqual(table.rows[0], ["a", "b", "c"])
        // A short row is padded rather than rejected.
        XCTAssertEqual(table.rows[1].count, 3)
        XCTAssertEqual(table.rows[1][0], "only one")
    }

    func testPipeTextWithoutADelimiterRowIsNotATable() {
        let blocks = MarkdownParser.parse("""
        This sentence | has a pipe in it
        and continues here
        """)
        XCTAssertFalse(blocks.contains { if case .table = $0 { return true }; return false })
    }

    // MARK: Quotes, rules, front matter

    func testQuotesRecordTheirNestingDepth() {
        let blocks = MarkdownParser.parse("""
        > first level
        >> second level
        """)
        XCTAssertEqual(blocks[0], .quote(depth: 1, text: "first level"))
        XCTAssertEqual(blocks[1], .quote(depth: 2, text: "second level"))
    }

    func testFrontMatterIsSkippedRatherThanRendered() {
        let blocks = MarkdownParser.parse("""
        ---
        title: Something
        tags: [a, b]
        ---

        # Real content
        """)
        XCTAssertEqual(blocks.count, 1)
        XCTAssertEqual(blocks[0], .heading(level: 1, text: "Real content"))
    }

    func testHorizontalRuleVariants() {
        for source in ["---", "***", "___", "- - -"] {
            let blocks = MarkdownParser.parse(source)
            XCTAssertEqual(blocks, [.rule], "\(source) should be a rule")
        }
    }

    func testStandaloneImageBecomesAnImageBlock() {
        let blocks = MarkdownParser.parse("![A diagram](diagrams/system.svg)")
        XCTAssertEqual(blocks[0], .image(alt: "A diagram", source: "diagrams/system.svg"))

        // An image with surrounding prose stays a paragraph, so the text is not lost.
        let inline = MarkdownParser.parse("See ![this](a.png) for details")
        XCTAssertEqual(inline[0], .paragraph(text: "See ![this](a.png) for details"))
    }

    func testHTMLIsCapturedAsABlockAndNeverExecuted() {
        let blocks = MarkdownParser.parse("<script>alert('x')</script>")
        XCTAssertEqual(blocks[0], .htmlBlock(text: "<script>alert('x')</script>"))
    }

    // MARK: Robustness

    func testLargeDocumentParsesQuickly() {
        var source = ""
        for index in 0..<4_000 {
            source += "## Heading \(index)\n\nSome paragraph text for section \(index).\n\n- item one\n- item two\n\n"
        }
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            let blocks = MarkdownParser.parse(source)
            XCTAssertGreaterThan(blocks.count, 10_000)
        }
        XCTAssertLessThan(elapsed, .seconds(3), "Parsing a large document took \(elapsed)")
    }

    func testPathologicalInputDoesNotCrash() {
        for source in ["", "\n\n\n", "```", "|||", "> > > >", "#", "    ", "\t\t\t"] {
            _ = MarkdownParser.parse(source)
        }
    }

    // MARK: File tree

    func testTreeSkipsNoiseDirectoriesAndNestsFolders() throws {
        let root = temporaryDirectory.appendingPathComponent("Repo", isDirectory: true)
        let docs = root.appendingPathComponent("docs", isDirectory: true)
        let modules = root.appendingPathComponent("node_modules/pkg", isDirectory: true)
        let derived = root.appendingPathComponent("DerivedData-Release", isDirectory: true)
        for directory in [docs, modules, derived] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try "# Root".write(to: root.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "# Guide".write(to: docs.appendingPathComponent("guide.md"), atomically: true, encoding: .utf8)
        try "# Nope".write(to: modules.appendingPathComponent("readme.md"), atomically: true, encoding: .utf8)
        try "# Nope".write(to: derived.appendingPathComponent("notes.md"), atomically: true, encoding: .utf8)
        try "not markdown".write(to: root.appendingPathComponent("data.txt"), atomically: true, encoding: .utf8)

        let tree = MarkdownFileTree.build(rootPath: root.path)

        XCTAssertEqual(MarkdownFileTree.fileCount(tree), 2, "node_modules and DerivedData must be skipped")
        // Folders sort before files.
        XCTAssertTrue(tree[0].isDirectory)
        XCTAssertEqual(tree[0].name, "docs")
        XCTAssertEqual(tree[1].name, "README.md")
        XCTAssertEqual(tree[0].children.first?.relativePath, "docs/guide.md")
    }

    func testBuiltAppBundlesAndPackagesAreNotTreatedAsDocumentation() throws {
        // A built .app carries a copy of every README as a bundled resource. Left unfiltered
        // those swamped the real documents — 45 of 50 entries in this project.
        let root = temporaryDirectory.appendingPathComponent("RepoBundles", isDirectory: true)
        let appResources = root.appendingPathComponent("build/Debug/Thing.app/Contents/Resources", isDirectory: true)
        let framework = root.appendingPathComponent("Carthage2/Some.framework/Resources", isDirectory: true)
        let lproj = root.appendingPathComponent("hi.lproj", isDirectory: true)
        for directory in [appResources, framework, lproj] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try "# Real".write(to: root.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "# Copy".write(to: appResources.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "# Copy".write(to: framework.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "# Copy".write(to: lproj.appendingPathComponent("notes.md"), atomically: true, encoding: .utf8)

        let tree = MarkdownFileTree.build(rootPath: root.path)
        XCTAssertEqual(MarkdownFileTree.fileCount(tree), 1, "Only the real README should survive")
        XCTAssertEqual(tree.first?.name, "README.md")

        for name in ["Thing.app", "Some.framework", "hi.lproj", "Thing.xcodeproj", "x.bundle", "y.dSYM"] {
            XCTAssertTrue(MarkdownFileTree.shouldSkip(directoryName: name), "\(name) should be skipped")
        }
        for name in ["docs", "Support", "worklog", "build"] {
            XCTAssertFalse(MarkdownFileTree.shouldSkip(directoryName: name), "\(name) should be kept")
        }
    }

    func testEmptyFoldersAreOmittedAndFilterKeepsMatchingDescendants() throws {
        let root = temporaryDirectory.appendingPathComponent("Repo2", isDirectory: true)
        let docs = root.appendingPathComponent("docs", isDirectory: true)
        let empty = root.appendingPathComponent("assets", isDirectory: true)
        for directory in [docs, empty] {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        try "x".write(to: empty.appendingPathComponent("logo.png"), atomically: true, encoding: .utf8)
        try "# Release".write(to: docs.appendingPathComponent("release-notes.md"), atomically: true, encoding: .utf8)
        try "# Other".write(to: docs.appendingPathComponent("other.md"), atomically: true, encoding: .utf8)

        let tree = MarkdownFileTree.build(rootPath: root.path)
        // A folder with no markdown below it is not shown at all.
        XCTAssertFalse(tree.contains { $0.name == "assets" })

        // Filtering keeps the parent folder when a child matches.
        let filtered = MarkdownFileTree.filter(tree, term: "release")
        XCTAssertEqual(MarkdownFileTree.fileCount(filtered), 1)
        XCTAssertEqual(filtered.first?.name, "docs")
        XCTAssertEqual(filtered.first?.children.first?.name, "release-notes.md")

        // No match yields nothing rather than everything.
        XCTAssertTrue(MarkdownFileTree.filter(tree, term: "zzzz").isEmpty)
        // An empty filter is a no-op.
        XCTAssertEqual(MarkdownFileTree.fileCount(MarkdownFileTree.filter(tree, term: "  ")), 2)
    }

    func testMarkdownExtensionsAndFirstFileSelection() throws {
        XCTAssertTrue(MarkdownFileTree.isMarkdown(URL(fileURLWithPath: "/a/b.md")))
        XCTAssertTrue(MarkdownFileTree.isMarkdown(URL(fileURLWithPath: "/a/b.MARKDOWN")))
        XCTAssertFalse(MarkdownFileTree.isMarkdown(URL(fileURLWithPath: "/a/b.txt")))

        let root = temporaryDirectory.appendingPathComponent("Repo3", isDirectory: true)
        let nested = root.appendingPathComponent("deep/deeper", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try "# Deep".write(to: nested.appendingPathComponent("first.md"), atomically: true, encoding: .utf8)

        let tree = MarkdownFileTree.build(rootPath: root.path)
        // Finds a file even when it is only present several folders down.
        XCTAssertEqual(MarkdownFileTree.firstFile(in: tree)?.name, "first.md")
        XCTAssertNil(MarkdownFileTree.firstFile(in: []))
    }

    func testRealProjectDocumentsParseWithoutLosingContent() throws {
        // The plan file for this very feature is a good adversarial sample: headings, tables,
        // fences, task lists, and rules all in one document.
        let planPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()          // Tests
            .deletingLastPathComponent()          // LXC-BRM
            .appendingPathComponent("Support/worklog/Plan-MarkdownExplorer-todo.md")
        guard let source = try? String(contentsOf: planPath, encoding: .utf8) else {
            throw XCTSkip("Plan file not present in this checkout")
        }
        let blocks = MarkdownParser.parse(source)
        XCTAssertTrue(blocks.contains { if case .heading = $0 { return true }; return false })
        XCTAssertTrue(blocks.contains { if case .table = $0 { return true }; return false })
        XCTAssertTrue(blocks.contains { if case .listItem = $0 { return true }; return false })
        // Nothing should come back empty.
        XCTAssertFalse(blocks.isEmpty)
    }
}
