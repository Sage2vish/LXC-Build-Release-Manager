[![Build & Test](https://github.com/Lexvora-Consulting/My-Health-Hub-Space/actions/workflows/ci.yml/badge.svg)](https://github.com/Lexvora-Consulting/My-Health-Hub-Space/actions/workflows/ci.yml)

# My Health Hub Space

My Health Hub Space is a native Swift/SwiftUI app by Lexvora Consulting for managing, building, and tracking multi-repository projects with local or GitHub sources. 

## Features
- Add and manage local folders or GitHub repositories
- Detects /build/scripts/ and creates build buttons for .sh scripts
- Live build output, streaming logs, and build history
- Per-repository stats, overview, and settings
- Preferences with native macOS Settings window
- All build and user data stored in Application Support; offline-friendly

## Getting Started
1. Open the project in Xcode 15 or later.
2. Run the app (Cmd+R) to launch.
3. Add a local folder or GitHub URL using the sidebar or Add button.
4. Use the Preferences window (Cmd+,) to configure behavior.

## Documentation
- User guide: `LXC-BRM-build-release/USER_GUIDE.md`
- Packaging/release: `LXC-BRM-build-release/README.md`
- Requirements: `LXC-BRM-context/requirements.md`

## Project Structure
- `App/` — Main Swift/SwiftUI app code
- `Frameworks/` — Shared code and modules
- `LXC-BRM-build-release/` — Build packaging, guides, templates
- `LXC-BRM-context/` — Requirements, decisions, architecture docs
- `worklog/` — Project todo/checklist and work tracking

## Contributing
PRs and issues are welcome! Please see the requirements and context docs before submitting changes. Please follow the project's Code of Conduct.
  
## License
See [LICENSE](LICENSE).

