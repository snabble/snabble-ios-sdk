//
//  AssetManager.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import UIKit
import SnabbleCore

// MARK: - ImageAsset

public enum ImageAsset: String, Sendable {
    // store icon, 24x24
    case storeIcon = "icon"
    // store logo (home view + store detail)
    case storeLogo = "logo"
    // store logo small (scanner/card title)
    case storeLogoSmall = "logo-small"
    // customer/loyalty card
    case customerCard = "loyaltycard"

    case startTeaserLoyalty = "start-teaser-loyalty"
    case startTeaserPayment = "start-teaser-payment"

    case checkoutOnline = "checkout-online"
    case checkoutOffline = "checkout-offline"

    case appBackgroundImage = "background-app"
}

// MARK: - SnabbleCI public bridge

extension SnabbleCI {
    /// Downloads manifests for all projects and calls `completion` on the main thread when done.
    public static func initializeAssets(for projects: [Project], completion: @escaping @Sendable () -> Void) {
        // Capture `shared` here (on the calling/main thread) to force lazy init on the main thread.
        // AssetManager.init uses MainActor.assumeIsolated to read UIScreen.main.scale.
        let manager = AssetManager.shared
        Task {
            await manager.initialize(projects)
            await MainActor.run { completion() }
        }
    }

    public static func initializeAssets(for projectId: Identifier<Project>, _ manifestUrl: String, downloadFiles: Bool) {
        let manager = AssetManager.shared
        Task {
            await manager.initialize(projectId, manifestUrl: manifestUrl, downloadFiles: downloadFiles)
        }
    }

    /// Retrieves a named asset asynchronously.
    /// Must only be called after `initializeAssets` has been called on the main thread.
    public static func getAsset(_ asset: ImageAsset, bundlePath: String? = nil, projectId: Identifier<Project>? = nil) async -> UIImage? {
        await AssetManager.shared.getAsset(asset, bundlePath: bundlePath, projectId: projectId)
    }

    /// Retrieves a named asset. `completion` is called on the main thread.
    public static func getAsset(_ asset: ImageAsset, bundlePath: String? = nil, projectId: Identifier<Project>? = nil, completion: @escaping @Sendable (UIImage?) -> Void) {
        let manager = AssetManager.shared
        Task {
            let image = await manager.getAsset(asset, bundlePath: bundlePath, projectId: projectId)
            await MainActor.run { completion(image) }
        }
    }

    // use this only for debugging
    public static func clearAssets() {
        let manager = AssetManager.shared
        Task { await manager.clearAssets() }
    }
}

// MARK: - Manifest

struct Manifest: Codable {
    let projectId: Identifier<Project>
    let files: [File]

    struct File: Codable, Hashable {
        let name: String
        let variants: Variants
    }

    // swiftlint:disable identifier_name
    struct Variants: Codable, Hashable {
        let x1: String?
        let x2: String?
        let x3: String?

        enum CodingKeys: String, CodingKey {
            case x1 = "1x"
            case x2 = "2x"
            case x3 = "3x"
        }
    }
    // swiftlint:enable identifier_name
}

extension Manifest.File {
    func remoteURL(for scale: CGFloat) -> URL? {
        guard let variant = self.variant(for: scale) else { return nil }
        return Snabble.shared.urlFor(variant)
    }

    private func variant(for scale: CGFloat) -> String? {
        switch scale {
        case 2: return self.variants.x2 ?? self.variants.x1
        case 3: return self.variants.x3 ?? self.variants.x1
        default: return self.variants.x1
        }
    }

    func localName(_ scale: CGFloat) -> String? {
        guard let variant = self.variant(for: scale) else { return nil }
        return "\(self.name)-\(variant.sha1)"
    }

    func defaultsKey(_ projectId: Identifier<Project>) -> String {
        "io.snabble.sdk.asset.\(projectId.rawValue).\(basename())"
    }

    private func basename() -> String {
        let parts = self.name.components(separatedBy: ".")
        return parts.count > 1 ? parts.dropLast().joined(separator: ".") : self.name
    }
}

// MARK: - AssetManager

/// Manages downloading and caching of project assets (logos, icons, etc.).
///
/// Actor isolation replaces the previous ReadWriteLock + @unchecked Sendable pattern.
/// Async/await URLSession APIs replace URLSessionDownloadDelegate callbacks.
actor AssetManager {
    static let shared = AssetManager()

    private var manifests = [Identifier<Project>: Manifest]()
    /// Keys of downloads currently in-flight; prevents duplicate concurrent requests for the same file.
    private var inFlightDownloads = Set<String>()
    private var redownloadTask: Task<Void, Never>?

    // `let` constants are implicitly nonisolated in actors — callers read them without await.
    let screenScale: CGFloat
    private let urlSession: URLSession
    private let buildRequest: @Sendable (URL, Bool) -> URLRequest

    private init(
        urlSession: URLSession = Snabble.urlSession,
        buildRequest: @escaping @Sendable (URL, Bool) -> URLRequest = { Snabble.request(url: $0, json: $1) }
    ) {
        self.screenScale = MainActor.assumeIsolated { UIScreen.main.scale }
        self.urlSession = urlSession
        self.buildRequest = buildRequest
    }

    // MARK: Public interface

    func getAsset(_ asset: ImageAsset, bundlePath: String?, projectId: Identifier<Project>?) async -> UIImage? {
        let projectId = projectId ?? SnabbleCI.project.id
        let name = asset.rawValue

        if let image = await locallyCachedImage(named: name, projectId: projectId) {
            return image
        }

        let interfaceStyle = await MainActor.run { UIScreen.main.traitCollection.userInterfaceStyle }
        return await processAssetRequest(name: name, projectId: projectId, interfaceStyle: interfaceStyle, bundlePath: bundlePath)
    }

    /// Downloads manifests for all projects concurrently, then saves them for the next launch.
    func initialize(_ projects: [Project]) async {
        let settingsKey = "Snabble.api.manifests"
        let settings = UserDefaults.standard

        if let data = settings.object(forKey: settingsKey) as? Data,
           let cached = try? JSONDecoder().decode([Identifier<Project>: Manifest].self, from: data) {
            manifests = cached
        }

        await withTaskGroup(of: Void.self) { group in
            for project in projects {
                guard let manifestUrl = project.links.assetsManifest?.href else { continue }
                group.addTask { await self.initialize(project.id, manifestUrl: manifestUrl, downloadFiles: false) }
            }
        }

        if let data = try? JSONEncoder().encode(manifests) {
            settings.set(data, forKey: settingsKey)
        }
    }

    func initialize(_ projectId: Identifier<Project>, manifestUrl: String, downloadFiles: Bool) async {
        guard
            let manifestUrl = Snabble.shared.urlFor(manifestUrl),
            var components = URLComponents(url: manifestUrl, resolvingAgainstBaseURL: false)
        else { return }

        let fmt = NumberFormatter()
        fmt.minimumFractionDigits = 0
        fmt.numberStyle = .decimal
        let variant = fmt.string(for: screenScale) ?? "1"

        components.queryItems = [URLQueryItem(name: "variant", value: "\(variant)x")]
        guard let url = components.url else { return }

        var request = buildRequest(url, true)
        request.timeoutInterval = 2

        let start = Date.timeIntervalSinceReferenceDate
        do {
            let (data, response) = try await urlSession.data(for: request)
            Log.info("GET \(url) took \(Date.timeIntervalSinceReferenceDate - start)s")

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard statusCode == 200 else {
                Log.error("Error downloading asset manifest for \(projectId): status \(statusCode)")
                return
            }

            let manifest = try JSONDecoder().decode(Manifest.self, from: data)
            manifests[projectId] = manifest
            if downloadFiles { downloadAllMissingFiles(projectId) }
        } catch {
            Log.info("GET \(url) took \(Date.timeIntervalSinceReferenceDate - start)s")
            Log.error("Error downloading asset manifest: \(error)")
        }
    }

    func cacheDirectory(_ projectId: Identifier<Project>) -> URL? {
        guard var url = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            return nil
        }
        url.appendPathComponent("assets")
        url.appendPathComponent(projectId.rawValue)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }

    func clearAssets() {
        for project in Snabble.shared.projects {
            if let url = cacheDirectory(project.id) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    // MARK: Private

    private func processAssetRequest(name: String, projectId: Identifier<Project>, interfaceStyle: UIUserInterfaceStyle, bundlePath: String?) async -> UIImage? {
        guard let file = fileFor(name: name, projectId, interfaceStyle) else {
            return UIImage.fromBundle(bundlePath)
        }

        // Prefetch the opposite color-scheme variant in the background.
        Task { await downloadOpposite(for: file, projectId: projectId, named: name, currentStyle: interfaceStyle) }

        guard let fileUrl = await downloadIfMissing(projectId, file),
              let data = try? Data(contentsOf: fileUrl) else {
            return UIImage.fromBundle(bundlePath)
        }
        return UIImage(data: data, scale: screenScale)
    }

    private func downloadOpposite(for file: Manifest.File, projectId: Identifier<Project>, named name: String, currentStyle: UIUserInterfaceStyle) async {
        let opposite = oppositeStyle(for: currentStyle)
        guard
            opposite != currentStyle,
            let oppositeFile = fileFor(name: name, projectId, opposite),
            oppositeFile != file
        else { return }

        await downloadIfMissing(projectId, oppositeFile)
    }

    @discardableResult
    private func downloadIfMissing(_ projectId: Identifier<Project>, _ file: Manifest.File) async -> URL? {
        guard
            let localName = file.localName(screenScale),
            let cacheUrl = cacheDirectory(projectId)
        else { return nil }

        let fullUrl = cacheUrl.appendingPathComponent(localName)

        if FileManager.default.fileExists(atPath: fullUrl.path) {
            return fullUrl
        }

        let downloadKey = "\(projectId.rawValue)/\(localName)"
        // The check and insert are both synchronous (before the first await), so actor isolation
        // guarantees atomicity — no two tasks can pass the guard for the same key.
        guard !inFlightDownloads.contains(downloadKey) else { return nil }
        inFlightDownloads.insert(downloadKey)
        defer { inFlightDownloads.remove(downloadKey) }

        guard let remoteUrl = file.remoteURL(for: screenScale) else { return nil }

        do {
            Log.info("start download for \(projectId)/\(localName)")
            let request = buildRequest(remoteUrl, false)
            let (tempUrl, _) = try await urlSession.download(for: request)
            try saveDownloadedFile(from: tempUrl, to: fullUrl, localName: localName, key: file.defaultsKey(projectId), cacheUrl: cacheUrl)
            return fullUrl
        } catch {
            Log.error("downloading \(remoteUrl) failed: \(error)")
            rescheduleDownloads()
            return nil
        }
    }

    private func saveDownloadedFile(from location: URL, to target: URL, localName: String, key: String, cacheUrl: URL) throws {
        if localName.contains("/") {
            let dir = cacheUrl.appendingPathComponent((localName as NSString).deletingLastPathComponent)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: target.path) {
            try? fileManager.removeItem(at: target)
        }
        try fileManager.moveItem(at: location, to: target)

        let settings = UserDefaults.standard
        let oldLocalFile = settings.string(forKey: key)
        settings.set(localName, forKey: key)

        if let old = oldLocalFile, old != localName {
            try? fileManager.removeItem(at: cacheUrl.appendingPathComponent(old))
        }
    }

    private func rescheduleDownloads() {
        redownloadTask?.cancel()
        redownloadTask = Task {
            do {
                try await Task.sleep(for: .seconds(10))
            } catch {
                return
            }
            for projectId in manifests.keys {
                downloadAllMissingFiles(projectId)
            }
        }
    }

    private func downloadAllMissingFiles(_ projectId: Identifier<Project>) {
        guard let manifest = manifests[projectId] else { return }

        let files = manifest.files.filter { !$0.name.contains("/") && hasValidExtension($0.name) }
        for file in files {
            Task { await self.downloadIfMissing(projectId, file) }
        }
    }

    private func locallyCachedImage(named name: String, projectId: Identifier<Project>) async -> UIImage? {
        guard let lightData = locallyCachedData(named: name, projectId: projectId, style: .light) else {
            return nil
        }
        let lightImage = UIImage(data: lightData, scale: screenScale)

        if let darkData = locallyCachedData(named: name, projectId: projectId, style: .dark),
           let darkImage = UIImage(data: darkData, scale: screenScale) {
            let scale = screenScale
            // UITraitCollection mutation and UIImageAsset registration are @MainActor-isolated.
            await MainActor.run {
                let traitCollection = UITraitCollection { mutableTraits in
                    mutableTraits.displayScale = scale
                    mutableTraits.userInterfaceStyle = .dark
                }
                lightImage?.imageAsset?.register(darkImage, with: traitCollection)
            }
        }
        return lightImage
    }

    private func locallyCachedData(named name: String, projectId: Identifier<Project>, style: UIUserInterfaceStyle) -> Data? {
        guard
            let file = fileFor(name: name, projectId, style),
            let cacheUrl = cacheDirectory(projectId),
            let localFilename = UserDefaults.standard.string(forKey: file.defaultsKey(projectId))
        else { return nil }

        return try? Data(contentsOf: cacheUrl.appendingPathComponent(localFilename))
    }

    private func fileFor(name: String, _ projectId: Identifier<Project>, _ style: UIUserInterfaceStyle) -> Manifest.File? {
        guard let manifest = manifests[projectId] else { return nil }

        if let file = manifest.files.first(where: { $0.name == name }) { return file }

        if style == .dark, let file = manifest.files.first(where: { filenameMatch("\(name)_dark", fullname: $0.name) }) {
            return file
        }
        return manifest.files.first { filenameMatch(name, fullname: $0.name) }
    }

    private func oppositeStyle(for style: UIUserInterfaceStyle) -> UIUserInterfaceStyle {
        switch style {
        case .light: return .dark
        case .dark: return .light
        default: return .unspecified
        }
    }

    private func filenameMatch(_ filename: String, fullname: String) -> Bool {
        guard let dot = fullname.lastIndex(of: ".") else { return filename == fullname }
        return filename == fullname[fullname.startIndex ..< dot] && hasValidExtension(fullname)
    }

    private func hasValidExtension(_ filename: String) -> Bool {
        let validExtensions = [".png", ".jpg", ".jpeg", ".gif"]
        guard let dot = filename.lastIndex(of: ".") else { return true }
        return validExtensions.contains(String(filename[dot...]).lowercased())
    }
}
