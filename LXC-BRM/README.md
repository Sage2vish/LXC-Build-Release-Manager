# LXC Build & Release Manager (LXC-BRM)

<p align="center">
  <img src="https://via.placeholder.com/128x128.png?text=BRM" alt="LXC-BRM Logo">
</p>

<p align="center">
  <strong>A native macOS application for discovering, running, and managing local build scripts with ease.</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#technology-stack">Tech Stack</a> •
  <a href="#project-status">Project Status</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-lightgrey.svg" alt="Platform: macOS">
  <img src="https://img.shields.io/badge/swift-5.9-orange.svg" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/swiftui-native-blue.svg" alt="SwiftUI Native">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License: MIT">
  <img src="https://img.shields.io/badge/status-in%20progress-yellow.svg" alt="Status: In Progress">
</p>

---

LXC-BRM is a developer utility designed to streamline your local build process. Point it at a repository, and it automatically detects shell scripts in a `/build/scripts` directory, presenting them as one-click actions. It provides live, timestamped log streaming, a complete build history, and project-specific statistics, all wrapped in a clean, native macOS interface.

## ✨ Features

*   **📂 Repository Management**: Add local repositories from your disk or scan public GitHub repositories.
*   **🤖 Automatic Script Detection**: Scans for `.sh` files within `/build/scripts/` and creates runnable commands.
*   **▶️ One-Click Build Execution**: Run any detected script as a background process with a single click.
*   **🔴 Live Log Streaming**: View `stdout` and `stderr` in real-time, with per-line timestamps in a terminal-style view.
*   **🔍 Log Search & Filtering**: Instantly search logs, highlight matches, and filter by Errors, Warnings, or Info.
*   **📜 Persistent Build History**: Every run is recorded with its status (Success, Failed, Cancelled) and duration.
*   **📊 Project Overview**: At-a-glance dashboard with success rates, average build times, and other key stats.
*   **📌 Multi-Repository Support**: Switch between multiple projects instantly, with pinned favorites for quick access.
*   **🎨 Native Look & Feel**: A pure Swift/SwiftUI app that respects system light/dark modes and macOS conventions.
*   **⚙️ Highly Configurable**: An extensive preferences panel to customize everything from build execution to appearance.

## 🚀 Quick Start

1.  **Launch the app.**
2.  Click **Add Repository** in the sidebar.
3.  Choose a local folder containing a `/build/scripts/` directory with your `.sh` build scripts.
4.  The repository will appear in the sidebar, and its available scripts will be listed in the **Build** tab.
5.  Click **Run** next to a script to start a build!

For more details, see the **User Guide**.

## 📸 Screenshots

*(This is where you would place screenshots of the application)*

<p align="center">
  <img src="https://via.placeholder.com/800x500.png?text=Main+Application+View" alt="Main Application View" style="width: 100%; max-width: 800px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
</p>

<p align="center">
  <img src="https://via.placeholder.com/800x500.png?text=Preferences+Window" alt="Preferences Window" style="width: 100%; max-width: 800px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
</p>


## 🛠️ Technology Stack

LXC-BRM is built with a focus on performance, stability, and a native user experience.

*   **Language**: **Swift 5**
*   **UI Framework**: **SwiftUI**
*   **App Framework**: **AppKit**
*   **Dependencies**: **None!** 100% first-party Apple frameworks.

The project follows a strict "no third-party dependencies" rule to ensure a lean, maintainable, and secure codebase.

## 📈 Project Status

The project is actively under development. The core feature set is largely complete and verified through code and build checks.

| Phase | Status | Checked / Total |
| :--- | :--- | :--- |
| 0 — Workspace Foundation | ✅ Done | 5 / 5 |
| 1 — Repository Input & Detection | ✅ Done | 9 / 9 |
| 2 — Build Execution & Management | ✅ Done | 5 / 5 |
| 3 — Log Storage & Retrieval | ✅ Done | 6 / 6 |
| 4 — Project & Build Overview | ✅ Done | 5 / 5 |
| 5 — Multi-Repository Support | ✅ Done | 5 / 5 |
| 6 — Non-Functional Hardening | 🟡 In Progress | 3 / 6 |
| 7 — Packaging & Deliverables | 🟡 In Progress | 3 / 4 |

For a detailed breakdown of all tasks, see the master **`todo-2026-08-16.md`** file.

> **Note**: While most features are code-complete, full interactive GUI testing is still pending.

## 🏗️ Building from Source

1.  Clone the repository.
2.  Open `LXC-BRM.xcodeproj` in Xcode.
3.  Select the `LXC-BRM` scheme and "My Mac" as the target.
4.  Press `Cmd+B` to build or `Cmd+R` to run.

For detailed packaging and release instructions, see the **Build Instructions**.

## 📜 License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

<p align="center">
  <em>Crafted with ❤️ for macOS developers.</em>
</p>