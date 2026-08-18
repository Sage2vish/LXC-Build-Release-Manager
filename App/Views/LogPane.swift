import SwiftUI
import AppKit

struct LogPane: View {
    let title: String
    let lines: [DisplayLine]
    let preferences: Preferences
    var onExport: (() -> Void)?
    var onOpenInWindow: (() -> Void)? = nil
    var onStop: (() -> Void)? = nil
    var onClear: (() -> Void)? = nil
    var isRunning = false
    /// When true the terminal takes whatever height its container gives it, instead of asking
    /// for a fixed band. The Build tab's split needs this: a hard 220pt minimum inside a pane
    /// that also had a 180pt minimum was what clipped the output as the window got shorter.
    var fillsAvailableHeight = false

    @State private var searchText = ""
    @State private var filter: LogFilter
    @State private var currentMatchIndex = 0
    @State private var isExpanded = false
    @State private var autoScroll = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        lines: [DisplayLine],
        preferences: Preferences,
        onExport: (() -> Void)? = nil,
        onOpenInWindow: (() -> Void)? = nil,
        onStop: (() -> Void)? = nil,
        onClear: (() -> Void)? = nil,
        isRunning: Bool = false,
        fillsAvailableHeight: Bool = false
    ) {
        self.title = title
        self.lines = lines
        self.preferences = preferences
        self.onExport = onExport
        self.onOpenInWindow = onOpenInWindow
        self.onStop = onStop
        self.onClear = onClear
        self.isRunning = isRunning
        self.fillsAvailableHeight = fillsAvailableHeight
        self._filter = State(initialValue: LogFilter(rawValue: preferences.defaultLogFilter) ?? .all)
        self._autoScroll = State(initialValue: preferences.autoScrollToBottom)
    }

    private var filtered: [DisplayLine] {
        lines.filter { filter.matches($0.text) }
    }

    private var matches: [DisplayLine] {
        guard !searchText.isEmpty else { return [] }
        return filtered.filter {
            preferences.searchIsCaseSensitive
                ? $0.text.contains(searchText)
                : $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var logFont: Font {
        let size = CGFloat(preferences.consoleFontSize)
        if preferences.useSystemFont {
            return .system(size: size, design: .monospaced)
        }
        return .custom(preferences.consoleFontName, size: size)
    }

    private var pastelBackgroundColor: Color {
        if colorScheme == .dark {
            return Color.black.opacity(0.82)
        } else {
            return Color(red: 244/255, green: 246/255, blue: 255/255, opacity: 0.82)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(isRunning ? "Streaming output from the running build" : "Output from the most recent build")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        // Same tinted subtitle bar as Available Build Scripts.
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.tint.opacity(0.10), in: Capsule())
                }
                Spacer()
                Picker("", selection: $filter) {
                    ForEach(LogFilter.allCases) { item in Text(item.rawValue).tag(item) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                // A ceiling, not a fixed width: four filter segments pinned at 260pt pushed the
                // whole toolbar row - and with it the centre column - past what a narrow window
                // could give it.
                .frame(minWidth: 160, maxWidth: 260)
                if let onStop {
                    Button(role: .destructive) { onStop() } label: {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .accessibilityLabel("Stop build")
                    .accessibilityHint("Stops the active build process.")
                    .disabled(!isRunning)
                }
                if let onClear {
                    Button { onClear() } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .accessibilityLabel("Clear output")
                    .accessibilityHint("Clears visible output without deleting saved build history.")
                    .disabled(lines.isEmpty)
                }
                Button {
                    isExpanded.toggle()
                } label: {
                    Label(
                        isExpanded ? "Restore Log Pane" : "Maximize Log Pane",
                        systemImage: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                    )
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(isExpanded ? "Restore log pane" : "Maximize log pane")
                .help(isExpanded ? "Restore log pane" : "Maximize log pane")
                if let onOpenInWindow {
                    Button { onOpenInWindow() } label: {
                        Label("Open in Separate Window", systemImage: "window")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Open log in a separate window")
                }
                if let onExport {
                    Button { onExport() } label: {
                        Label("Save Log", systemImage: "square.and.arrow.down")
                    }
                    .tint(Color(red: 166/255, green: 209/255, blue: 247/255)) // pastel blue tone
                    .accessibilityLabel("Save Log to file")
                    .help("Export the full output to a file.")
                    .disabled(lines.isEmpty)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search log…", text: $searchText)
                    .textFieldStyle(.plain)
                    .onChange(of: searchText) { _, _ in currentMatchIndex = 0 }
                    .accessibilityLabel("Search log")
                    .accessibilityHint("Enter text to filter log lines")
                if !searchText.isEmpty {
                    Text(matches.isEmpty ? "0 matches" : "\(currentMatchIndex + 1) of \(matches.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button { step(-1) } label: { Image(systemName: "chevron.up") }
                        .disabled(matches.isEmpty)
                        .accessibilityLabel("Previous match")
                    Button { step(1) } label: { Image(systemName: "chevron.down") }
                        .disabled(matches.isEmpty)
                        .accessibilityLabel("Next match")
                }
            }
            .padding(6)
            .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 6))
            .cornerRadius(6)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: CGFloat(preferences.lineSpacing) * 2) {
                        ForEach(Array(filtered.enumerated()), id: \.element.id) { index, line in
                            HStack(alignment: .top, spacing: 8) {
                                if preferences.showLineNumbers {
                                    Text("\(index + 1)")
                                        .foregroundStyle(.white.opacity(0.35))
                                        .frame(width: 34, alignment: .trailing)
                                        .accessibilityLabel("Line number \(index + 1)")
                                }
                                if !line.timestampText.isEmpty {
                                    Text(line.timestampText)
                                        .foregroundStyle(.white.opacity(0.55))
                                }
                                streamBadge(for: line.stream)
                                Text(line.text)
                                    .textSelection(.enabled)
                                    .lineLimit(preferences.wordWrap ? nil : 1)
                                    .truncationMode(.tail)
                                    .foregroundStyle(color(for: line))
                                    .font(.system(size: CGFloat(preferences.consoleFontSize), design: .monospaced))
                            }
                            .font(logFont)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                matches.contains(where: { $0.id == line.id }) ? Color.yellow.opacity(0.3) : .clear
                            )
                            .id(line.id)
                        }
                        if filtered.isEmpty {
                            Text(lines.isEmpty ? "Waiting for build output…" : "No log lines match the current filter.")
                                .foregroundStyle(.white.opacity(0.6))
                                .padding()
                        }
                    }
                    .padding(8)
                }
                .frame(
                    minHeight: fillsAvailableHeight ? 80 : 180,
                    maxHeight: fillsAvailableHeight ? .infinity : (isExpanded ? 720 : 420)
                )
                .background(pastelBackgroundColor)
                .foregroundStyle(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .onAppear {
                    if autoScroll, let last = filtered.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: filtered.count) { _, _ in
                    if autoScroll, let last = filtered.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
                .onChange(of: currentMatchIndex) { _, newValue in
                    guard matches.indices.contains(newValue) else { return }
                    if reduceMotion {
                        proxy.scrollTo(matches[newValue].id, anchor: .center)
                    } else {
                        withAnimation { proxy.scrollTo(matches[newValue].id, anchor: .center) }
                    }
                }
            }

            HStack {
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                    .font(.caption)
                    .accessibilityLabel("Auto-scroll")
                    .accessibilityHint("Turn this off to read earlier output without following new lines.")
                Spacer()
                Text("\(filtered.count) lines")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Build output log area")
    }

    @ViewBuilder
    private func streamBadge(for stream: LogStream) -> some View {
        switch stream {
        case .stderr:
            Text("ERR")
                .font(.caption2.weight(.bold).monospaced())
                .foregroundStyle(.red.opacity(0.9))
                .frame(width: 28, alignment: .leading)
                .accessibilityLabel("Standard error")
        case .system:
            Text("SYS")
                .font(.caption2.weight(.bold).monospaced())
                .foregroundStyle(.cyan.opacity(0.9))
                .frame(width: 28, alignment: .leading)
                .accessibilityLabel("Build system")
        case .stdout:
            Color.clear.frame(width: 28, height: 1)
                .accessibilityHidden(true)
        }
    }

    private func color(for line: DisplayLine) -> Color {
        guard preferences.colorizeOutput else { return .white }
        if let ansiColor = line.ansiColor { return ansiColor.color }
        if line.stream == .stderr { return .orange }
        let lower = line.text.lowercased()
        if lower.contains("error") || lower.contains("failed") { return .red }
        if lower.contains("warning") { return .orange }
        if lower.contains("success") || lower.contains("succeeded") { return .green }
        return .white
    }

    private func step(_ delta: Int) {
        guard !matches.isEmpty else { return }
        currentMatchIndex = (currentMatchIndex + delta + matches.count) % matches.count
    }
}

@MainActor
final class LogWindowController {
    static let shared = LogWindowController()
    private var window: NSWindow?

    func show(title: String, rootView: some View) {
        if let window {
            window.title = title
            window.contentViewController = NSHostingController(rootView: AnyView(rootView))
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 720),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = title
        newWindow.titleVisibility = .visible
        newWindow.contentViewController = NSHostingController(rootView: AnyView(rootView))
        newWindow.center()
        newWindow.makeKeyAndOrderFront(nil)
        self.window = newWindow
        NSApp.activate(ignoringOtherApps: true)
    }
}
