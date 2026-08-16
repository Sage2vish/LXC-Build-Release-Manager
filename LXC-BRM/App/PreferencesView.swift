import SwiftUI

struct PreferencesView: View {
    var body: some View {
        Form {
            Section("General") {
                LabeledContent("Appearance", value: "Follows system")
                LabeledContent("Platform", value: "macOS")
            }
            Section("Build") {
                LabeledContent("Auto-detect build scripts", value: "Enabled")
                Text("Scans /build/scripts/ automatically whenever a repository is opened or switched to.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("Storage") {
                LabeledContent("Recent repositories & history", value: "~/Library/Application Support/LXC-BRM/")
            }
        }
        .formStyle(.grouped)
        .frame(width: 440, height: 280)
    }
}
