//
//  AssetManager.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import UIKit

public enum ImageAsset: String {
    // store icon, 24x24
    case storeIcon = "icon"
    // store logo (home view + store detail)
    case storeLogo = "logo"
    // store logo small (scanner/card title)
    case storeLogoSmall = "logo-small"
    // customer/loyalty card
    case customerCard = "loyaltycard"

    // checkout
    case checkoutOnline = "checkout-online"
    case checkoutOffline = "checkout-offline"
}

extension SnabbleUI {
    // download manifests for all projects, calls `completion` when all downloads are done
    public static func initializeAssets(for projects: [Project], completion: @escaping () -> Void) {
        AssetManager.instance.initialize(projects, completion)
    }

    public static func initializeAssets(for projectId: String, _ manifestUrl: String, downloadFiles: Bool) {
        AssetManager.instance.initialize(projectId, manifestUrl, downloadFiles, completion: { })
    }

    public static func getAsset(_ asset: ImageAsset, bundlePath: String? = nil, projectId: String? = nil, completion: @escaping (UIImage?) -> Void) {
        AssetManager.instance.getAsset(asset, bundlePath, projectId, completion)
    }

    // use this only for debugging
    public static func clearAssets() {
        AssetManager.instance.clearAssets()
    }
}

struct Manifest: Codable {
    let projectId: String
    let files: [File]

    struct File: Codable, Hashable {
        let name: String
        let variants: Variants
    }

    // swiftlint:disable identifier_name nesting
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
    // swiftlint:enable identifier_name nesting
}

extension Manifest {
    func remoteURL(for name: String, at scale: CGFloat) -> URL? {
        guard let file = self.files.first(where: { $0.name == "\(name).png" }) else {
            return nil
        }

        return file.remoteURL(for: scale)
    }
}

extension Manifest.File {
    // where can we download this thing from?
    func remoteURL(for scale: CGFloat) -> URL? {
        guard let variant = self.variant(for: scale) else {
            return nil
        }
        return SnabbleAPI.urlFor(variant)
    }

    private func variant(for scale: CGFloat) -> String? {
        switch scale {
        case 2: return self.variants.x2 ?? self.variants.x1
        case 3: return self.variants.x3 ?? self.variants.x1
        default: return self.variants.x1
        }
    }

    // filename for our local filesystem copy (usually in .cachesDirectory)
    func localName(_ projectId: String, _ scale: CGFloat) -> String? {
        guard let variant = self.variant(for: scale) else {
            return nil
        }

        let name = "\(self.name)-\(variant.sha1)"
        return name
    }

    // full path for our local filesystem copy
    func localPath(_ projectId: String, _ scale: CGFloat) -> URL? {
        guard let localName = self.localName(projectId, scale) else {
            return nil
        }

        let cacheUrl = AssetManager.instance.cacheDirectory(projectId)
        return cacheUrl.appendingPathComponent(localName)
    }

    // where we store information about this file in UserDefaults
    func defaultsKey(_ projectId: String) -> String {
        return "io.snabble.sdk.asset.\(projectId).\(self.basename())"
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

final class AssetManager {
    static let instance = AssetManager()

    private var manifests = [String: Manifest]()
    private let scale: CGFloat

    private var redownloadTimer: Timer?

    private init() {
        self.scale = UIScreen.main.scale
    }

    /// Get a named asset, or its local fallback
    /// - Parameters:
    ///   - name: name of the asset, e.g. "checkout-offline"
    ///   - bundlePath: bundle path of the fallback to use, e.g. "Checkout/$PROJECTID/checkout-offline"
    ///   - projectId: the project id. If nil, use `SnabbleUI.project.id`
    ///   - completion: called when the image has been retrieved
    func getAsset(_ asset: ImageAsset, _ bundlePath: String?, _ projectId: String?, _ completion: @escaping (UIImage?) -> Void) {
        let projectId = projectId ?? SnabbleUI.project.id
        let name = asset.rawValue
        if let image = self.getLocallyCachedImage(named: name, projectId) {
            completion(image)
        } else {
            if let file = self.fileFor(name: name, projectId) {
                self.downloadIfMissing(projectId, file) { fileUrl in
                    if let fileUrl = fileUrl, let data = try? Data(contentsOf: fileUrl) {
                        let img = UIImage(data: data, scale: self.scale)
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
            } else {
                let img = UIImage.fromBundle(bundlePath)
                completion(img)
            }
        }
    }

    private func getLocallyCachedImage(named name: String, _ projectId: String) -> UIImage? {
        guard let file = self.fileFor(name: name, projectId) else {
            return nil
        }

        let settings = UserDefaults.standard
        if let localFilename = settings.string(forKey: file.defaultsKey(projectId)) {
            let cacheUrl = self.cacheDirectory(projectId)
            let fileUrl = cacheUrl.appendingPathComponent(localFilename)
            if let data = try? Data(contentsOf: fileUrl) {
                return UIImage(data: data, scale: self.scale)
            }
        }

        return nil
    }

    private func fileFor(name: String, _ projectId: String) -> Manifest.File? {
        guard let manifest = self.manifests[projectId] else {
            return nil
        }

        // in dark mode, check if we have a _dark version, and if so, use that
        if #available(iOS 13.0, *), UIScreen.main.traitCollection.userInterfaceStyle == .dark {
            let file = manifest.files.first(where: { $0.name == name + "_dark.png" })
            if file != nil {
                return file
            }
        }

        let file = manifest.files.first(where: { $0.name == name + ".png" })
        return file
    }

    func initialize(_ projects: [Project], _ completion: @escaping () -> Void) {
        let group = DispatchGroup()
        for project in projects {
            if let manifestUrl = project.links.assetsManifest?.href {
                group.enter()
                self.initialize(project.id, manifestUrl, false) {
                    group.leave()
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            completion()
        }
    }

    func initialize(_ projectId: String, _ manifestUrl: String, _ downloadFiles: Bool, completion: @escaping () -> Void) {
        guard
            let manifestUrl = SnabbleAPI.urlFor(manifestUrl),
            var components = URLComponents(url: manifestUrl, resolvingAgainstBaseURL: false)
        else {
            return
        }

        let fmt = NumberFormatter()
        fmt.minimumFractionDigits = 0
        fmt.numberStyle = .decimal
        let variant = fmt.string(for: self.scale)!

        components.queryItems = [
            URLQueryItem(name: "type", value: "png"),
            URLQueryItem(name: "variant", value: "\(variant)x")
        ]

        guard let url = components.url else {
            return
        }

        let session = URLSession.shared
        let start = Date.timeIntervalSinceReferenceDate
        var request = SnabbleAPI.request(url: url, json: true)
        request.timeoutInterval = 2
        let task = session.dataTask(with: request) { data, response, error in
            let elapsed = Date.timeIntervalSinceReferenceDate - start
            Log.info("get \(url) took \(elapsed)s")

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
                self.manifests[projectId] = manifest
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
        self.redownloadTimer?.invalidate()

        DispatchQueue.main.async {
            self.redownloadTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                for projectId in self.manifests.keys {
                    self.downloadAllMissingFiles(projectId)
                }
                self.redownloadTimer = nil
            }
        }
    }

    private func downloadAllMissingFiles(_ projectId: String) {
        guard let manifest = self.manifests[projectId] else {
            return
        }

        // initially download all PNGs in the toplevel directory (ie. no "/" in the `name`)
        for file in manifest.files.filter({ $0.name.hasSuffix(".png") && !$0.name.contains("/") }) {
            self.downloadIfMissing(projectId, file, completion: { _ in })
        }
    }

    private func downloadIfMissing(_ projectId: String, _ file: Manifest.File, completion: @escaping (URL?) -> Void) {
        guard let localName = file.localName(projectId, self.scale) else {
            return
        }

        let cacheUrl = AssetManager.instance.cacheDirectory(projectId)
        let fullUrl = cacheUrl.appendingPathComponent(localName)

        let fileManager = FileManager.default
        // uncomment to force download
        // try? fileManager.removeItem(at: fullUrl)

        if !fileManager.fileExists(atPath: fullUrl.path) {
            let downloadDelegate = DownloadDelegate(projectId, localName, file.defaultsKey(projectId), completion)
            let session = URLSession(configuration: .default, delegate: downloadDelegate, delegateQueue: nil)

            if let remoteUrl = file.remoteURL(for: self.scale) {
                let request = SnabbleAPI.request(url: remoteUrl, json: false)
                let task = session.downloadTask(with: request)
                task.resume()
            }
        }
    }

    func cacheDirectory(_ projectId: String) -> URL {
        let fileManager = FileManager.default
        // swiftlint:disable:next force_try
        var url = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        url.appendPathComponent("assets")
        url.appendPathComponent(projectId)
        try? fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)

        return url
    }

    // remove all asset directories. use this only for debugging/during development
    func clearAssets() {
        let fileManager = FileManager.default

        for project in SnabbleAPI.projects {
            let url = self.cacheDirectory(project.id)
            try? fileManager.removeItem(at: url)
        }
    }
}

private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {

    private let projectId: String
    private let localName: String
    private let key: String
    private let completion: (URL?) -> Void
    private let startDate: TimeInterval

    init(_ projectId: String, _ localName: String, _ key: String, _ completion: @escaping (URL?) -> Void) {
        self.projectId = projectId
        self.localName = localName
        self.key = key
        self.completion = completion
        self.startDate = Date.timeIntervalSinceReferenceDate
        Log.info("start download for \(self.projectId)/\(self.localName)")
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let cacheDirUrl = AssetManager.instance.cacheDirectory(self.projectId)

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
            AssetManager.instance.rescheduleDownloads()
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
        AssetManager.instance.rescheduleDownloads()
        session.invalidateAndCancel()
    }
}
