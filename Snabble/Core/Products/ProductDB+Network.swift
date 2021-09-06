//
//  ProductDB+Network.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

enum AppDbResponse {
    case diff(lines: URL)
    case full(db: URL)
    case noUpdate   // no data, used when we get http 304
    case httpError  // http or network error
    case dataError  // data error: invalid content-type, unparsable data or other weird things
    case aborted    // download was aborted. app may attempt resuming later
}

extension ProductDB {
    fileprivate static let sqlType = "application/vnd+snabble.appdb+sql"
    fileprivate static let sqliteType = "application/vnd+snabble.appdb+sqlite3"
    private static let contentTypes = "\(sqlType),\(sqliteType)"

    private func appDbSession(_ completion: @escaping (AppDbResponse) -> Void) -> URLSession {
        let delegate = AppDBDownloadDelegate(self, completion)
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }

    func getAppDb(currentRevision: Int64, schemaVersion: String, forceFullDb: Bool = false, completion: @escaping (AppDbResponse) -> Void ) {
        let parameters = [
            "havingRevision": "\(currentRevision)",
            "schemaVersion": schemaVersion
        ]

        if self.downloadTask != nil {
            Log.warn("appDB download task already running, ignoring update request")
            completion(.noUpdate)
            return
        }

        self.project.request(.get, self.project.links.appdb.href, json: false, parameters: parameters, timeout: 0) { [self] request in
            guard var request = request else {
                return completion(.httpError)
            }

            request.setValue(ProductDB.contentTypes, forHTTPHeaderField: "Accept")

            let session = appDbSession(completion)
            downloadTask = session.downloadTask(with: request)
            downloadTask?.resume()
        }
    }

    func resumeAppDbDownload(_ completion: @escaping (AppDbResponse) -> Void ) {
        guard let resumeData = self.resumeData else {
            return
        }

        if self.downloadTask != nil {
            Log.warn("appDB download task already running, ignoring resume request")
            return
        }

        Log.info("resuming download of appdb")

        let session = self.appDbSession(completion)
        downloadTask = session.downloadTask(withResumeData: resumeData)
        downloadTask?.resume()
    }

}

final class AppDBDownloadDelegate: CertificatePinningDelegate, URLSessionDownloadDelegate {
    private var completion: (AppDbResponse) -> Void
    private var response: URLResponse?
    private weak var productDb: ProductDB?
    private let start = Date.timeIntervalSinceReferenceDate
    private var bytesReceived: Int64 = 0
    private var mbps = 0.0 // megabytes/second

    init(_ productDb: ProductDB, _ completion: @escaping (AppDbResponse) -> Void) {
        self.productDb = productDb
        self.completion = completion
    }

    // MARK: - download delegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let elapsed = Date.timeIntervalSinceReferenceDate - self.start
        self.bytesReceived += bytesWritten

        if elapsed > 0 {
            self.mbps = Double(self.bytesReceived) / elapsed / 1024 / 1024
        }
        // print("download progress: \(totalBytesWritten ) \(self.mbps)")
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let url = downloadTask.currentRequest?.url?.absoluteString ?? "n/a"
        let elapsed = Date.timeIntervalSinceReferenceDate - self.start
        Log.info("GET \(url) took \(elapsed)s")

        if let response = downloadTask.response as? HTTPURLResponse {
            // print("got bytes: \(data.count) \(self.bytesReceived), \(self.mbps) MB/s")
            if response.statusCode == 304 {
                completion(.noUpdate)
                session.invalidateAndCancel()
                return
            }

            // move the downloaded data to our own temp file
            let fileManager = FileManager.default
            let tmpDir: URL
            do {
                tmpDir = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: location, create: true)
            } catch {
                Log.error("error creating tmp dir: \(error)")
                completion(.dataError)
                session.invalidateAndCancel()
                return
            }

            let tmpFile = tmpDir.appendingPathComponent(ProcessInfo().globallyUniqueString)
            do {
                try fileManager.moveItem(at: location, to: tmpFile)
                self.tmpFile = tmpFile
            } catch {
                Log.error("error moving \(location) to \(tmpFile): \(error)")
                completion(.dataError)
                session.invalidateAndCancel()
                return
            }
        }
    }

    private var tmpFile: URL?

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        tmpFile = nil
        productDb?.resumeData = nil
        productDb?.downloadTask = nil

        if let error = error as NSError? {
            let url = task.currentRequest?.url?.absoluteString ?? "n/a"
            Log.info("\(url) finished with error \(error.code)")

            let userInfo = error.userInfo
            if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                self.productDb?.resumeData = resumeData
                self.completion(.aborted)
            } else {
                self.completion(.httpError)
            }
        } else if let response = task.response as? HTTPURLResponse, let tmpFile = tmpFile {
            switch response.allHeaderFields["Content-Type"] as? String {
            case ProductDB.sqliteType:
                completion(.full(db: tmpFile))
            case ProductDB.sqlType:
                completion(.diff(lines: tmpFile))
            default:
                completion(.dataError)
            }
        } else {
            completion(.dataError)
        }
    }
}
