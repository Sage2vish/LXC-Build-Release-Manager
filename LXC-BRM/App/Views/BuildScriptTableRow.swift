import SwiftUI
import AppKit

struct BuildScriptTableRow: View {
    let script: BuildScript
    let lastRunText: String
    let lastRunColor: Color
    let isSelected: Bool
    let isRunning: Bool
    let canRun: Bool
    let onSelect: () -> Void
    let onRun: () -> Void
    let onStop: () -> Void
    let onReveal: () -> Void
    let onCopyPath: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isRunning ? "circle.dotted" : "terminal")
                .foregroundStyle(isRunning ? .blue : .secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text(script.label)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                // Folder name only. The full path is long enough to squeeze the action
                // columns off-screen, so it lives in the Detail View Window instead.
                Label(script.folderName, systemImage: "folder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)

            locationBadge
                .frame(width: 122, alignment: .leading)

            Text(script.parameters.isEmpty ? "No parameters" : "\(script.parameters.count) parameter\(script.parameters.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 108, alignment: .leading)

            Label(lastRunText, systemImage: isRunning ? "circle.dotted" : "clock")
                .font(.caption)
                .foregroundStyle(lastRunColor)
                .frame(width: 126, alignment: .leading)

            if isRunning {
                Button("Stop", role: .destructive, action: onStop)
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Stop \(script.label)")
            } else {
                Button("Run", action: onRun)
                    .buttonStyle(.borderedProminent)
                    .disabled(!canRun)
                    .accessibilityLabel("Run \(script.label)")
            }

            Menu {
                Button("Select") { onSelect() }
                Button("Run", action: onRun).disabled(!canRun)
                Button("Reveal in Finder", action: onReveal).disabled(script.isRemote)
                Button("Copy Script Path", action: onCopyPath)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .accessibilityLabel("More actions for \(script.label)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { isHovered = $0 }
        .focusable()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(script.label), \(script.location.label), \(lastRunText)")
        .accessibilityHint("Select this script to review parameters and command preview.")
        .accessibilityAction(named: "Run") { onRun() }
        .background(background)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.primary.opacity(isHovered ? 0.12 : 0.06), lineWidth: isSelected ? 1.5 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contextMenu {
            Button("Run", action: onRun).disabled(!canRun)
            Button("Reveal in Finder", action: onReveal).disabled(script.isRemote)
            Button("Copy Script Path", action: onCopyPath)
        }
    }

    private var background: Color {
        if isSelected { return Color.accentColor.opacity(0.12) }
        if isHovered { return Color.primary.opacity(0.06) }
        if !canRun && !isRunning { return Color.secondary.opacity(0.05) }
        return Color.primary.opacity(0.025)
    }

    @ViewBuilder
    private var locationBadge: some View {
        switch script.location {
        case .standardFolder:
            Label("Standard", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
        case .repository:
            Label("In repo", systemImage: "folder.fill").foregroundStyle(.blue)
        case .outsideRepository:
            Label("Outside", systemImage: "externaldrive.fill").foregroundStyle(.orange)
        case .missing, .stale:
            Label(script.location == .stale ? "Stale" : "Missing", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
        case .unavailable:
            Label("Remote only", systemImage: "icloud.slash").foregroundStyle(.secondary)
        }
    }
}
