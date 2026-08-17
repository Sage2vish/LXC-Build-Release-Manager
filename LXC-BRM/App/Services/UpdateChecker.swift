import Foundation

/// A version like `0.1.2`, comparable properly.
///
/// String comparison gets this wrong — `"0.1.10" < "0.1.9"` is true as text — so releases are
/// parsed into numeric components before being ordered.
struct AppVersion: Comparable, Equatable, CustomStringConvertible {
    let components: [Int]
    /// Suffix after `-`, e.g. `beta.1`. A version carrying one sorts *below* the same version
    /// without it, matching semver.
    let prerelease: String?

    var description: String {
        let base = components.map(String.init).joined(separator: ".")
        return prerelease.map { "\(base)-\($0)" } ?? base
    }

    /// Parses `0.1.2`, `v0.1.2`, `1.0`, `0.2.0-beta.1`. Returns `nil` for anything else, so junk
    /// in a release name can never be read as a newer version.
    init?(_ raw: String) {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.lowercased().hasPrefix("v") { text.removeFirst() }
        guard !text.isEmpty else { return nil }

        let split = text.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
        let numeric = String(split[0])
        prerelease = split.count > 1 && !split[1].isEmpty ? String(split[1]) : nil

        let parts = numeric.split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty else { return nil }
        var parsed: [Int] = []
        for part in parts {
            guard let value = Int(part), value >= 0 else { return nil }
            parsed.append(value)
        }
        components = parsed
    }

    /// Compares component-by-component, padding the shorter side with zeros.
    /// Returns `nil` when the numeric parts are equal, leaving the prerelease to decide.
    private static func compareComponents(_ lhs: AppVersion, _ rhs: AppVersion) -> Bool? {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            // Missing trailing components are zero, so 1.0 and 1.0.0 are the same version.
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return nil
    }

    /// Synthesized equality would compare `[1, 0]` against `[1, 0, 0]` and call them different,
    /// which would report a phantom update. Equality has to pad the same way ordering does.
    static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        compareComponents(lhs, rhs) == nil && lhs.prerelease == rhs.prerelease
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        if let ordered = compareComponents(lhs, rhs) { return ordered }
        switch (lhs.prerelease, rhs.prerelease) {
        case (nil, nil): return false
        case (_?, nil): return true      // 1.0.0-beta < 1.0.0
        case (nil, _?): return false
        case (let l?, let r?): return l < r
        }
    }
}

/// A release newer than the running build.
struct AvailableUpdate: Equatable {
    let version: AppVersion
    let name: String
    let releaseURL: URL?
    let isPrerelease: Bool
}

/// Checks GitHub Releases for a newer build.
///
/// Backs `checkForUpdatesAutomatically` and `updateChannel`, which were stored and shown with
/// nothing behind them. It only reports that a newer version exists and where to get it —
/// downloading and installing stay manual, deliberately.
enum UpdateChecker {
    static let releasesEndpoint = URL(string: "https://api.github.com/repos/Sage2vish/LXC-Build-Release-Manager/releases")!

    enum Channel: Equatable {
        case stable
        case beta

        init(preference: String) {
            self = preference.lowercased().contains("beta") ? .beta : .stable
        }

        /// Stable ignores prereleases; Beta accepts them. Drafts are never offered.
        func accepts(prerelease: Bool, draft: Bool) -> Bool {
            if draft { return false }
            return self == .beta || !prerelease
        }
    }

    enum Result: Equatable {
        case upToDate(current: AppVersion)
        case updateAvailable(AvailableUpdate, current: AppVersion)
        case failed(String)
    }

    /// One entry from the releases endpoint.
    struct ReleaseEntry: Decodable, Equatable {
        let tagName: String
        let name: String?
        let htmlURL: String?
        let prerelease: Bool
        let draft: Bool

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name
            case htmlURL = "html_url"
            case prerelease
            case draft
        }
    }

    /// The running app's version, read from the bundle rather than hardcoded.
    static func currentVersion(bundle: Bundle = .main) -> AppVersion? {
        guard let raw = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            return nil
        }
        return AppVersion(raw)
    }

    /// Pure selection logic, separated from the network so it can be tested directly.
    static func evaluate(
        releases: [ReleaseEntry],
        channel: Channel,
        current: AppVersion
    ) -> Result {
        let candidates: [(AppVersion, ReleaseEntry)] = releases.compactMap { entry in
            guard channel.accepts(prerelease: entry.prerelease, draft: entry.draft),
                  let version = AppVersion(entry.tagName) else { return nil }
            return (version, entry)
        }

        guard let best = candidates.max(by: { $0.0 < $1.0 }) else {
            return .upToDate(current: current)
        }
        guard best.0 > current else { return .upToDate(current: current) }

        return .updateAvailable(
            AvailableUpdate(
                version: best.0,
                name: best.1.name?.isEmpty == false ? best.1.name! : best.1.tagName,
                releaseURL: best.1.htmlURL.flatMap(URL.init(string:)),
                isPrerelease: best.1.prerelease
            ),
            current: current
        )
    }

    /// Fetches and evaluates. Never throws into the caller; failures come back as `.failed`.
    static func check(
        preferences: Preferences,
        bundle: Bundle = .main,
        session: URLSession = .shared
    ) async -> Result {
        guard let current = currentVersion(bundle: bundle) else {
            return .failed("Could not read the running app version.")
        }

        var request = URLRequest(url: releasesEndpoint)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        if !preferences.gitHubToken.isEmpty {
            request.setValue("Bearer \(preferences.gitHubToken)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failed("Unexpected response from GitHub.")
            }
            if let warning = GitHubRateLimit.message(
                for: http,
                warnPercent: GitHubRateLimit.warnPercent(preferences.gitHubRateLimitAlertThreshold)
            ) {
                return .failed(warning)
            }
            guard http.statusCode == 200 else {
                return .failed("GitHub returned status \(http.statusCode) while checking for updates.")
            }
            let releases = try JSONDecoder().decode([ReleaseEntry].self, from: data)
            return evaluate(
                releases: releases,
                channel: Channel(preference: preferences.updateChannel),
                current: current
            )
        } catch {
            DiagnosticsLog.write(.error, "Update check failed: \(error.localizedDescription)", preferences: preferences)
            return .failed("Could not reach GitHub to check for updates.")
        }
    }
}
