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

public class AssetManager {
    public static let instance = AssetManager()

    private var manifest: Manifest?
    private var projectId: String
    private let scale: CGFloat

    private var redownloadTimer: Timer?

    private init() {
        self.projectId = ""
        self.scale = UIScreen.main.scale
    }

    public func getImage(named name: String) -> UIImage? {
        var name = name
        if #available(iOS 13.0, *), UIScreen.main.traitCollection.userInterfaceStyle == .dark {
            name += "_dark"
        }

        guard let file = self.manifest?.files.first(where: { $0.name == name + ".png" }) else {
            return nil
        }

        let settings = UserDefaults.standard
        if let localFilename = settings.string(forKey: file.defaultsKey(projectId)) {
            let fileManager = FileManager.default
            // swiftlint:disable:next force_try
            let cacheDirUrl = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = cacheDirUrl.appendingPathComponent(localFilename)
            if let data = try? Data(contentsOf: fileUrl) {
                return UIImage(data: data)
            }
        }

        self.downloadIfMissing(file)
        return nil
    }

    func initialize(for projectId: String, _ manifestUrl: String) {
        self.projectId = projectId

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
        let task = session.dataTask(with: url) { data, _, error in
            guard let data = data else {
                print("Error downloading asset manifest: \(String(describing: error))")
                return
            }
            do {
                let manifest = try JSONDecoder().decode(Manifest.self, from: data)
                self.manifest = manifest
                self.downloadAllMissingFiles()
            } catch {
                print(error)
            }
        }
        task.resume()
    }

    func rescheduleDownloads() {
        self.redownloadTimer?.invalidate()

        DispatchQueue.main.async {
            self.redownloadTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                self.downloadAllMissingFiles()
                self.redownloadTimer = nil
            }
        }
    }

    private func downloadAllMissingFiles() {
        guard let manifest = self.manifest else {
            return
        }

        for file in manifest.files.filter({ $0.name.hasSuffix(".png") }) {
            self.downloadIfMissing(file)
        }
    }

    private func downloadIfMissing(_ file: Manifest.File) {
        do {
            let fileManager = FileManager.default
            let cacheDirUrl = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

            guard let localName = file.localName(self.projectId, self.scale) else {
                return
            }

            let fullUrl = cacheDirUrl.appendingPathComponent(localName)

            // print("check d/l for \(file.name): \(localName) \(file.defaultsKey(self.projectId))")
            // uncomment to force download
            try? fileManager.removeItem(at: fullUrl)

            if !fileManager.fileExists(atPath: fullUrl.path) {
                let downloadDelegate = DownloadDelegate(localName: localName, key: file.defaultsKey(self.projectId))
                let session = URLSession(configuration: .default, delegate: downloadDelegate, delegateQueue: nil)

                if let remoteUrl = file.remoteURL(for: self.scale) {
                    let task = session.downloadTask(with: remoteUrl)
                    task.resume()
                }
            }
        } catch {
            print(error)
        }
    }

    private func createTargetDir(_ url: URL) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = nil

        if let dir = components?.url?.deletingLastPathComponent().path {
            do {
                let fileManager = FileManager.default

                if !fileManager.fileExists(atPath: dir) {
                    try fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
                }
            } catch {
                print(error)
            }
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
            print(error)
            AssetManager.instance.rescheduleDownloads()
        }
        session.finishTasksAndInvalidate()
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error as NSError? else {
            return
        }

        if let url = task.currentRequest?.url?.absoluteString {
            print("downloading \(url) failed: \(error)")
        }

        AssetManager.instance.rescheduleDownloads()
        session.invalidateAndCancel()
    }
}
