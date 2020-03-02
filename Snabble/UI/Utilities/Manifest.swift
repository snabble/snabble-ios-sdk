//
//  Manifest.swift
//  SnabbleApp
//
//  Created by Gereon Steffens on 28.01.20.
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

struct Manifest: Codable {
    let projectId: String
    fileprivate let files: [File]

    func fileUrl(for name: String, at scale: Int) -> URL? {
        if #available(iOS 13.0, *), UIScreen.main.traitCollection.userInterfaceStyle == .dark {
            if let file = self.pickVariant(for: name + "_dark", at: scale) {
                return file
            }
        }

        return self.pickVariant(for: name, at: scale)
    }

    private func pickVariant(for name: String, at scale: Int) -> URL? {
        guard let file = self.files.first(where: { $0.name == "\(name).png" }) else {
            return nil
        }

        return file.variantURL(for: scale)
    }
}

private struct File: Codable {
    let name: String
    let variants: Variants

    func variantURL(for scale: Int) -> URL {
        switch scale {
        case 2: return self.variants.x2 ?? self.variants.x1
        case 3: return self.variants.x3 ?? self.variants.x1
        default: return self.variants.x1
        }
    }

    func localPath() -> String {
        let fileManager = FileManager.default
        var cacheDirUrl = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

        cacheDirUrl.appendPathComponent(self.name)
    }
}

// swiftlint:disable identifier_name
private struct Variants: Codable {
    let x1: URL
    let x2, x3: URL?

    enum CodingKeys: String, CodingKey {
        case x1 = "1x"
        case x2 = "2x"
        case x3 = "3x"
    }
}
// swiftlint:enable identifier_name

class AssetManager {
    static let instance = AssetManager()

    private init() {}

    func getImage(named name: String) -> UIImage? {
        let settings = UserDefaults.standard

        let key = "io.snabble.sdk.asset.\(name)"
        if let localFilename = settings.string(forKey: key) {
            let fileManager = FileManager.default
            let cacheDirUrl = try! fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fileUrl = cacheDirUrl.appendingPathComponent(localFilename)
            if let data = try? Data(contentsOf: fileUrl) {
                return UIImage(data: data)
            }
        }

        #warning("download asset here")
        return nil
    }

    func initialize(for projectId: String, scale: Int) {
        let baseUrl = SnabbleAPI.config.baseUrl

        #warning("pass manifest URL as parameter")
        var components = URLComponents(string: "\(baseUrl)/\(projectId)/assets/manifest.json")
        components?.queryItems = [
            URLQueryItem(name: "type", value: "png"),
            URLQueryItem(name: "scale", value: "\(scale)")
        ]
        guard let url = components?.url else {
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
                for file in manifest.files.filter({ $0.name.hasSuffix(".png") }) {
                    self.downloadIfMissing(file, scale, projectId)
                }
            } catch {
                print(error)
            }
        }
        task.resume()
    }

    private func downloadIfMissing(_ file: File, _ scale: Int, _ projectId: String) {
        guard
            let fileUrl = file.variantURL(for: scale),
            let fileComponents = URLComponents(url: fileUrl, resolvingAgainstBaseURL: false)
        else {
            return
        }

        let fileManager = FileManager.default
        do {
            let cacheDirUrl = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fullUrl = cacheDirUrl.appendingPathComponent(fileComponents.path + "_" + (fileComponents.query ?? ""))

            // uncomment to force download
            try? fileManager.removeItem(at: fullUrl)

            // create target dir if necessary
            self.createTargetDir(fullUrl)

            if !fileManager.fileExists(atPath: fullUrl.path) {
                let downloadDelegate = DownloadDelegate(targetLocation: fullUrl)
                let session = URLSession(configuration: .default, delegate: downloadDelegate, delegateQueue: nil)

                if let assetUrl = SnabbleAPI.urlFor(fileUrl.absoluteString) {
                    let task = session.downloadTask(with: assetUrl)
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

    private let targetLocation: URL

    init(targetLocation: URL) {
        self.targetLocation = targetLocation
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            print("move file to \(self.targetLocation.path)")
            try FileManager.default.moveItem(at: location, to: self.targetLocation)
        } catch {
            print(error)
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
        session.invalidateAndCancel()
    }
}
