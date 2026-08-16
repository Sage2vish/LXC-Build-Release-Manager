import AppKit
import SwiftUI

struct AddRepositorySheet: View {
    @ObservedObject var store: RepositoryStore
    @Binding var isPresented: Bool
    @State private var githubURL = ""

    private var trimmedURL: String {
        githubURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValidGitHubURL: Bool {
        guard let url = URL(string: trimmedURL), let host = url.host, host.contains("github.com") else { return false }
        return url.pathComponents.filter { $0 != "/" }.count >= 2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Repository")
                .font(.title2.weight(.semibold))
            Text("Point to a local folder or paste a GitHub repository URL.")
                .foregroundStyle(.secondary)

            Button {
                pickLocalFolder()
            } label: {
                Label("Choose Local Folder…", systemImage: "folder")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("GitHub URL")
                    .font(.callout.weight(.medium))
                TextField("https://github.com/user/repo", text: $githubURL)
                    .textFieldStyle(.roundedBorder)
                if !trimmedURL.isEmpty && !isValidGitHubURL {
                    Text("Enter a full GitHub repo URL, like https://github.com/user/repo")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                Button("Add GitHub Repository") {
                    store.addGitHubRepository(urlString: trimmedURL)
                    isPresented = false
                }
                .disabled(!isValidGitHubURL)
            }

            HStack {
                Spacer()
                Button("Cancel") { isPresented = false }
            }
        }
        .padding(24)
        .frame(width: 420)
    }

    private func pickLocalFolder() {
        guard let path = presentLocalFolderPickerPath() else { return }
        store.addLocalRepository(path: path)
        isPresented = false
    }
}

@MainActor
func presentLocalFolderPickerPath() -> String? {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    panel.prompt = "Open Repository"
    guard panel.runModal() == .OK, let url = panel.url else { return nil }
    return url.path
}
