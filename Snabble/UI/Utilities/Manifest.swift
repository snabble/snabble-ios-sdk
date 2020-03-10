//
//  Manifest.swift
//  SnabbleApp
//
//  Created by Gereon Steffens on 28.01.20.
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation
import UIKit

struct Manifest: Codable {
    let projectId: String
    let files: [File]

    struct File: Codable {
        let name: String
        let variants: Variants
    }

    // swiftlint:disable identifier_name nesting
    struct Variants: Codable {
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

        let name = "\(self.name)-\(projectId)-\(variant.sha1)"
        return name
    }

    // full path for our local filesystem copy
    func localPath(_ projectId: String, _ scale: CGFloat) -> URL? {
        guard let localName = self.localName(projectId, scale) else {
            return nil
        }

        let fileManager = FileManager.default
        // swiftlint:disable:next force_try
        let cacheDirUrl = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return cacheDirUrl.appendingPathComponent(localName)
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

public final class AssetManager {
    public static let instance = AssetManager()

    private var manifests = [String: Manifest]()
    private let scale: CGFloat

    private var redownloadTimer: Timer?

    private init() {
        self.scale = UIScreen.main.scale
    }

    func getAsset(_ name: String, _ bundlePath: String) -> UIImage? {
        if let image = self.getImage(named: name) {
            return image
        } else {
            return UIImage.fromBundle(bundlePath + "/" + name)
        }
    }

    func getImage(named name: String) -> UIImage? {
        var name = name
        if #available(iOS 13.0, *), UIScreen.main.traitCollection.userInterfaceStyle == .dark {
            name += "_dark"
        }

        let projectId = SnabbleUI.project.id
        guard
            let manifest = self.manifests[projectId],
            let file = manifest.files.first(where: { $0.name == name + ".png" })
        else {
            return nil
        }

        let settings = UserDefaults.standard
        if let localFilename = settings.string(forKey: file.defaultsKey(projectId)) {
            let fileManager = FileManager.default
            // swiftlint:disable:next force_try
            let cacheDirUrl = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = cacheDirUrl.appendingPathComponent(localFilename)
            if let data = try? Data(contentsOf: fileUrl) {
                return UIImage(data: data, scale: self.scale)
            }
        }

        self.downloadIfMissing(projectId, file)
        return nil
    }

    public func initialize(for projects: [Project]) {
        let group = DispatchGroup()
        for project in projects {
            if let manifestUrl = project.links.assetsManifest?.href {
                group.enter()
                self.initialize(for: project.id, manifestUrl, downloadFiles: false) {
                    group.leave()
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            print("all manifests downloaded!")
        }
    }

    func initialize(for projectId: String, _ manifestUrl: String, downloadFiles: Bool, completion: @escaping () -> Void) {
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
        let task = session.dataTask(with: url) { data, _, error in
            let elapsed = Date.timeIntervalSinceReferenceDate - start
            Log.info("get \(url) took \(elapsed)s")
            guard let data = data else {
                Log.error("Error downloading asset manifest: \(String(describing: error))")
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
            completion()
        }
        task.resume()
    }

    func rescheduleDownloads() {
        self.redownloadTimer?.invalidate()

        DispatchQueue.main.async {
            self.redownloadTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
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

        for file in manifest.files.filter({ $0.name.hasSuffix(".png") }) {
            self.downloadIfMissing(projectId, file)
        }
    }

    private func downloadIfMissing(_ projectId: String, _ file: Manifest.File) {
        do {
            let fileManager = FileManager.default
            let cacheDirUrl = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

            guard let localName = file.localName(projectId, self.scale) else {
                return
            }

            let fullUrl = cacheDirUrl.appendingPathComponent(localName)

            // uncomment to force download
            // try? fileManager.removeItem(at: fullUrl)

            if !fileManager.fileExists(atPath: fullUrl.path) {
                let downloadDelegate = DownloadDelegate(localName: localName, key: file.defaultsKey(projectId))
                let session = URLSession(configuration: .default, delegate: downloadDelegate, delegateQueue: nil)

                if let remoteUrl = file.remoteURL(for: self.scale) {
                    let task = session.downloadTask(with: remoteUrl)
                    task.resume()
                }
            }
        } catch {
            Log.error("Error downloading file: \(error)")
        }
    }
}

private final class DownloadDelegate: NSObject, URLSessionDownloadDelegate {

    private let localName: String
    private let key: String

    init(localName: String, key: String) {
        self.localName = localName
        self.key = key
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            let fileManager = FileManager.default

            let cacheDirUrl = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let targetLocation = cacheDirUrl.appendingPathComponent(self.localName)
            print("download for \(localName) finished")
            // print("move file to \(targetLocation.path)")

            try fileManager.moveItem(at: location, to: targetLocation)

            let settings = UserDefaults.standard
            let oldLocalfile = settings.string(forKey: self.key)
            settings.set(self.localName, forKey: self.key)

            if let oldLocal = oldLocalfile, oldLocal != self.localName {
                let oldUrl = cacheDirUrl.appendingPathComponent(oldLocal)
                try? fileManager.removeItem(at: oldUrl)
            }
        } catch {
            Log.error("Error downloading asset for key \(self.key): \(error)")
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

        AssetManager.instance.rescheduleDownloads()
        session.invalidateAndCancel()
    }
}
