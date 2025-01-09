//
//  AssetManager.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import UIKit
import SnabbleCore

public enum ImageAsset: String {
    // store icon, 24x24
    case storeIcon = "icon"
    // store logo (home view + store detail)
    case storeLogo = "logo"
    // store logo small (scanner/card title)
    case storeLogoSmall = "logo-small"
    // customer/loyalty card
    case customerCard = "loyaltycard"

    // hint customer/loyalty card
    case startTeaserLoyalty = "start-teaser-loyalty"
    // hint payment card
    case startTeaserPayment = "start-teaser-payment"

    // checkout
    case checkoutOnline = "checkout-online"
    case checkoutOffline = "checkout-offline"

    // app start screen bg
    case appBackgroundImage = "background-app"
}

extension SnabbleCI {
    // download manifests for all projects, calls `completion` when all downloads are done
    public static func initializeAssets(for projects: [Project], completion: @escaping () -> Void) {
        AssetManager.shared.initialize(projects, completion)
    }

    public static func initializeAssets(for projectId: Identifier<Project>, _ manifestUrl: String, downloadFiles: Bool) {
        AssetManager.shared.initialize(projectId, manifestUrl, downloadFiles: downloadFiles, completion: { })
    }

    public static func getAsset(_ asset: ImageAsset, bundlePath: String? = nil, projectId: Identifier<Project>? = nil, completion: @escaping (UIImage?) -> Void) {
        AssetManager.shared.getAsset(asset, bundlePath, projectId, completion)
    }

    // use this only for debugging
    public static func clearAssets() {
        AssetManager.shared.clearAssets()
    }
}

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
    // where can we download this thing from?
    func remoteURL(for scale: CGFloat) -> URL? {
        guard let variant = self.variant(for: scale) else {
            return nil
        }
        return Snabble.shared.urlFor(variant)
    }

    private func variant(for scale: CGFloat) -> String? {
        switch scale {
        case 2: return self.variants.x2 ?? self.variants.x1
        case 3: return self.variants.x3 ?? self.variants.x1
        default: return self.variants.x1
        }
    }

    // filename for our local filesystem copy (usually in .cachesDirectory)
    func localName(_ scale: CGFloat) -> String? {
        guard let variant = self.variant(for: scale) else {
            return nil
        }

        let name = "\(self.name)-\(variant.sha1)"
        return name
    }

    // where we store information about this file in UserDefaults
    func defaultsKey(_ projectId: Identifier<Project>) -> String {
        return "io.snabble.sdk.asset.\(projectId.rawValue).\(self.basename())"
    }

    private func basename() -> String {
        let parts = self.name.components(separatedBy: ".")
        if parts.count > 1 {
            return parts.dropLast().joined(separator: ".")
        } else {
            return self.name
        }
    }
}

private struct AssetRequest {
    let asset: ImageAsset
    let bundlePath: String?
    let projectId: Identifier<Project>
    let completion: (UIImage?) -> Void
}

final class AssetManager {
    static let shared = AssetManager()

    private var manifests = [Identifier<Project>: Manifest]()
    private var lock = ReadWriteLock()

    private weak var redownloadTimer: Timer?

    /// Get a named asset, or its local fallback
    /// - Parameters:
    ///   - asset: type of the asset, e.g. `.checkoutOffline`
    ///   - bundlePath: bundle path of the fallback to use, e.g. "Checkout/$PROJECTID/checkout-offline"
    ///   - projectId: the project id. If nil, use `SnabbleUI.project.id`
    ///   - completion: called when the image has been retrieved
    func getAsset(_ asset: ImageAsset, _ bundlePath: String?, _ projectId: Identifier<Project>?, _ completion: @escaping (UIImage?) -> Void) {
        let projectId = projectId ?? SnabbleCI.project.id
        let name = asset.rawValue
        
        if let image = self.getLocallyCachedImage(named: name, projectId) {
            completion(image)
        } else {
            let interfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle
            if let file = self.fileFor(name: name, projectId, interfaceStyle) {
                self.downloadIfMissing(projectId, file) { fileUrl in
                    if let fileUrl = fileUrl, let data = try? Data(contentsOf: fileUrl) {
                        let img = UIImage(data: data, scale: UIScreen.main.scale)
                        DispatchQueue.main.async {
                            completion(img)
                        }
                    } else {
                        DispatchQueue.main.async {
                            let img = UIImage.fromBundle(bundlePath)
                            completion(img)
                        }
                    }
                }
                
                // check if there is an "opposite" (light vs dark) file that we also need to download
                downloadOpposite(for: file, projectId, named: name)
            } else {
                let img = UIImage.fromBundle(bundlePath)
                completion(img)
            }
        }
    }

    private func oppositeStyle(for style: UIUserInterfaceStyle) -> UIUserInterfaceStyle {
        switch style {
        case .light: return .dark
        case .dark: return .light
        default: return .unspecified
        }
    }

    // download the "opposite" of `file`, if it exists
    private func downloadOpposite(for file: Manifest.File, _ projectId: Identifier<Project>, named name: String) {
        let interfaceStyle = UIScreen.main.traitCollection.userInterfaceStyle
        let oppositeStyle = oppositeStyle(for: interfaceStyle)
        guard
            oppositeStyle != interfaceStyle,
            let oppositeFile = self.fileFor(name: name, projectId, oppositeStyle),
            oppositeFile != file
        else {
            return
        }

        self.downloadIfMissing(projectId, oppositeFile) { _ in }
    }

    private func getLocallyCachedImage(named name: String, _ projectId: Identifier<Project>) -> UIImage? {
        guard let lightData = getLocallyCachedData(named: name, projectId, .light) else {
            return nil
        }

        let lightImage = UIImage(data: lightData, scale: UIScreen.main.scale)

        if let darkData = getLocallyCachedData(named: name, projectId, .dark), let darkImage = UIImage(data: darkData, scale: UIScreen.main.scale) {
            let traitCollection = UITraitCollection { mutableTraits in
                mutableTraits.displayScale = UIScreen.main.scale
                mutableTraits.userInterfaceStyle = .dark
            }

            lightImage?.imageAsset?.register(darkImage, with: traitCollection)
        }
        return lightImage
    }

    private func getLocallyCachedData(named name: String, _ projectId: Identifier<Project>, _ userInterfaceStyle: UIUserInterfaceStyle) -> Data? {
        guard let file = self.fileFor(name: name, projectId, userInterfaceStyle) else {
            return nil
        }

        let settings = UserDefaults.standard
        if let localFilename = settings.string(forKey: file.defaultsKey(projectId)) {
            if let cacheUrl = self.cacheDirectory(projectId) {
                let fileUrl = cacheUrl.appendingPathComponent(localFilename)
                return try? Data(contentsOf: fileUrl)
            }
        }

        return nil
    }

    private func fileFor(name: String, _ projectId: Identifier<Project>, _ userInterfaceStyle: UIUserInterfaceStyle) -> Manifest.File? {
        guard let manifest = lock.reading({ self.manifests[projectId] }) else {
            return nil
        }

        // if we find an exact match for the name, use that
        if let file = manifest.files.first(where: { $0.name == name }) {
            return file
        }

        // else we assume it's a name without file extension

        // in dark mode, check if we have a _dark version, and if so, use that
        if userInterfaceStyle == .dark {
            if let file = manifest.files.first(where: { filenameMatch("\(name)_dark", fullname: $0.name) }) {
                return file
            }
        }

        let file = manifest.files.first { filenameMatch(name, fullname: $0.name) }
        return file
    }

    private func filenameMatch(_ filename: String, fullname: String) -> Bool {
        if let dot = fullname.lastIndex(of: ".") {
            let basename = fullname[fullname.startIndex ..< dot]
            return filename == basename && hasValidExtension(fullname)
        }

        return filename == fullname
    }

    private func hasValidExtension(_ filename: String) -> Bool {
        let validExtensions = [ ".png", ".jpg", ".jpeg", ".gif" ]
        if let dot = filename.lastIndex(of: ".") {
            let ext = filename[dot ..< filename.endIndex]
            return validExtensions.contains(ext.lowercased())
        }

        return true
    }

    func initialize(_ projects: [Project], _ completion: @escaping () -> Void) {
        let settingsKey = "Snabble.api.manifests"
        let settings = UserDefaults.standard

        // pre-initialize with data from last download
        if let manifestData = settings.object(forKey: settingsKey) as? Data {
            do {
                let manifests = try JSONDecoder().decode([Identifier<Project>: Manifest].self, from: manifestData)
                self.manifests = manifests
            } catch {
                print(error)
            }
        }

        let group = DispatchGroup()
        for project in projects {
            if let manifestUrl = project.links.assetsManifest?.href {
                group.enter()
                self.initialize(project.id, manifestUrl, downloadFiles: false) {
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            // save manifests for next start
            do {
                let manifestData = try JSONEncoder().encode(self.manifests)
                settings.set(manifestData, forKey: settingsKey)
            } catch {
                print(error)
            }

            completion()
        }
    }

    func initialize(_ projectId: Identifier<Project>, _ manifestUrl: String, downloadFiles: Bool, completion: @escaping () -> Void) {
        guard
            let manifestUrl = Snabble.shared.urlFor(manifestUrl),
            var components = URLComponents(url: manifestUrl, resolvingAgainstBaseURL: false)
        else {
            return
        }

        let fmt = NumberFormatter()
        fmt.minimumFractionDigits = 0
        fmt.numberStyle = .decimal
        let variant = fmt.string(for: UIScreen.main.scale)!

        components.queryItems = [
            URLQueryItem(name: "variant", value: "\(variant)x")
        ]

        guard let url = components.url else {
            return
        }

        let session = Snabble.urlSession
        let start = Date.timeIntervalSinceReferenceDate
        var request = Snabble.request(url: url, json: true)
        request.timeoutInterval = 2
        let task = session.dataTask(with: request) { data, response, error in
            let elapsed = Date.timeIntervalSinceReferenceDate - start
            Log.info("GET \(url) took \(elapsed)s")

            defer { completion() }

            if let error = error {
                Log.error("Error downloading asset manifest: \(error)")
                return
            }

            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard statusCode == 200, let data = data else {
                Log.error("Error downloading asset manifest for \(projectId): \(statusCode)")
                return
            }

            do {
                let manifest = try JSONDecoder().decode(Manifest.self, from: data)
                self.lock.writing {
                    self.manifests[projectId] = manifest
                }
                if downloadFiles {
                    self.downloadAllMissingFiles(projectId)
                }
            } catch {
                Log.error("Error parsing manifest: \(error)")
            }
        }
        task.resume()
    }

    func rescheduleDownloads() {
        DispatchQueue.main.async {
            self.redownloadTimer?.invalidate()
            self.redownloadTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                for projectId in self.manifests.keys {
                    self.downloadAllMissingFiles(projectId)
                }
            }
        }
    }

    private func downloadAllMissingFiles(_ projectId: Identifier<Project>) {
        guard let manifest = lock.reading({ self.manifests[projectId] }) else {
            return
        }

        // initially download all files in the toplevel directory (ie. no "/" in the `name`)
        let initialFiles = manifest.files
            .filter { !$0.name.contains("/") && hasValidExtension($0.name) }

        for file in initialFiles {
            self.downloadIfMissing(projectId, file, completion: { _ in })
        }
    }

    private func downloadIfMissing(_ projectId: Identifier<Project>, _ file: Manifest.File, completion: @escaping (URL?) -> Void) {
        guard
            let localName = file.localName(UIScreen.main.scale),
            let cacheUrl = AssetManager.shared.cacheDirectory(projectId)
        else {
            return
        }

        let fullUrl = cacheUrl.appendingPathComponent(localName)

        let fileManager = FileManager.default
        // uncomment to force download
        // try? fileManager.removeItem(at: fullUrl)

        if !fileManager.fileExists(atPath: fullUrl.path) {
            let downloadDelegate = AssetDownloadDelegate(projectId, localName, file.defaultsKey(projectId), completion)
            let session = URLSession(configuration: .default, delegate: downloadDelegate, delegateQueue: nil)

            if let remoteUrl = file.remoteURL(for: UIScreen.main.scale) {
                let request = Snabble.request(url: remoteUrl, json: false)
                let task = session.downloadTask(with: request)
                task.resume()
            }
        }
    }

    func cacheDirectory(_ projectId: Identifier<Project>) -> URL? {
        let fileManager = FileManager.default
        guard var url = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            return nil
        }

        url.appendPathComponent("assets")
        url.appendPathComponent(projectId.rawValue)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        return url
    }

    // remove all asset directories. use this only for debugging/during development
    func clearAssets() {
        let fileManager = FileManager.default

        for project in Snabble.shared.projects {
            if let url = self.cacheDirectory(project.id) {
                try? fileManager.removeItem(at: url)
            }
        }
    }
}

private final class AssetDownloadDelegate: NSObject, URLSessionDownloadDelegate {
    private let projectId: Identifier<Project>
    private let localName: String
    private let key: String
    private let completion: (URL?) -> Void
    private let startDate: TimeInterval

    init(_ projectId: Identifier<Project>, _ localName: String, _ key: String, _ completion: @escaping (URL?) -> Void) {
        self.projectId = projectId
        self.localName = localName
        self.key = key
        self.completion = completion
        self.startDate = Date.timeIntervalSinceReferenceDate
        Log.info("start download for \(self.projectId)/\(self.localName)")
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let cacheDirUrl = AssetManager.shared.cacheDirectory(self.projectId) else {
            return
        }

        do {
            cacheResponse(session, downloadTask, location)

            if self.localName.contains("/") {
                // make sure any reqired subdirectories exist
                let dirname = (self.localName as NSString).deletingLastPathComponent
                let dir = cacheDirUrl.appendingPathComponent(dirname)
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            let targetLocation = cacheDirUrl.appendingPathComponent(self.localName)
            // let elapsed = Date.timeIntervalSinceReferenceDate - self.startDate
            // print("download for \(self.localName) finished \(elapsed)s")
            // print("move file to \(targetLocation.path)")

            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: targetLocation.path) {
                try? fileManager.removeItem(at: targetLocation)
            }

            try fileManager.moveItem(at: location, to: targetLocation)

            let settings = UserDefaults.standard
            let oldLocalfile = settings.string(forKey: self.key)
            settings.set(self.localName, forKey: self.key)

            if let oldLocal = oldLocalfile, oldLocal != self.localName {
                let oldUrl = cacheDirUrl.appendingPathComponent(oldLocal)
                try? fileManager.removeItem(at: oldUrl)
            }
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                self.completion(targetLocation)
            }
        } catch {
            Log.error("Error saving asset for key \(self.key): \(error)")
            self.completion(nil)
            AssetManager.shared.rescheduleDownloads()
        }
        session.finishTasksAndInvalidate()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error as NSError? else {
            return
        }

        if let url = task.currentRequest?.url?.absoluteString {
            Log.error("downloading \(url) failed: \(error)")
        }

        self.completion(nil)
        AssetManager.shared.rescheduleDownloads()
        session.invalidateAndCancel()
    }

    private func cacheResponse(_ session: URLSession, _ task: URLSessionDownloadTask, _ location: URL) {
        guard
            let response = task.response,
            let request = task.currentRequest,
            let cache = session.configuration.urlCache,
            cache.cachedResponse(for: request) == nil,
            let data = try? Data(contentsOf: location)
        else {
            return
        }

        cache.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
    }
}
