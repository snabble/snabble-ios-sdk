//
//  ProductDbNetwork.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

enum AppDbResponse {
    case diff(lines: String)
    case full(db: Data, revision: Int)
    case noUpdate   // no data, used when we get http 304
    case httpError  // http or network error
    case dataError  // data error: invalid content-type, unparsable data or other weird things
}

extension ProductDB {

    fileprivate static let sqlType = "application/vnd+snabble.appdb+sql"
    fileprivate static let sqliteType = "application/vnd+snabble.appdb+sqlite3"
    private static let contentTypes = "\(sqlType),\(sqliteType)"
    
    func getAppDb(currentRevision: Int64, schemaVersion: String, forceFullDb: Bool = false, completion: @escaping (AppDbResponse) -> () ) {
        let parameters = [
            "havingRevision": "\(currentRevision)",
            "schemaVersion": schemaVersion
        ]

        self.project.request(.get, self.project.links.appdb.href, json: false, parameters: parameters, timeout: 0) { request in
            guard var request = request else {
                return completion(.httpError)
            }

            request.setValue(ProductDB.contentTypes, forHTTPHeaderField: "Accept")
            let delegate = AppDBDownloadDelegate(completion)
            let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: OperationQueue.main)

            let task = session.downloadTask(with: request)
            task.resume()
        }
    }
}

class AppDBDownloadDelegate: CertificatePinningDelegate, URLSessionDownloadDelegate {

    private var completion: (AppDbResponse) -> ()
    private var response: URLResponse?
    private var resumeData: Data?

    init(_ completion: @escaping (AppDbResponse) -> ()) {
        self.completion = completion
    }

    // MARK: - download delegate

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let url = downloadTask.currentRequest?.url?.absoluteString
        print("\(String(describing: url)) \(bytesWritten) \(totalBytesWritten) \(totalBytesExpectedToWrite)")
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let url = downloadTask.currentRequest?.url?.absoluteString
        print("\(String(describing: url)) finished downloading")

        let fileData = try? Data(contentsOf: location)
        if let data = fileData, let response = downloadTask.response as? HTTPURLResponse {
            if response.statusCode == 304 {
                completion(.noUpdate)
                return
            }

            let headers = response.allHeaderFields
            if let contentType = headers["Content-Type"] as? String {
                if contentType == ProductDB.sqliteType {
                    if let etag = headers["Etag"] as? String {
                        completion(.full(db: data, revision: self.parseEtag(etag)))
                        return
                    }
                } else if contentType == ProductDB.sqlType {
                    if let str = String(bytes: data, encoding: .utf8) {
                        completion(.diff(lines: str))
                        return
                    }
                }
            }

            completion(.dataError)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else {
            return
        }

        let url = task.currentRequest?.url?.absoluteString
        print("\(String(describing: url)) finished with error \(String(describing: error))")
        self.completion(.httpError)

        let userInfo = (error as NSError).userInfo
        if let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
            self.resumeData = resumeData
        }
    }

    // https://developer.apple.com/documentation/foundation/url_loading_system/pausing_and_resuming_downloads

    // parse an ETag header value to extract the db revision
    // format is either W/"xyz" (for weak tags) or simply "xyz"
    private func parseEtag(_ etag: String) -> Int {
        let isWeak = etag.lowercased().hasPrefix("w/")
        let startIndex = isWeak ? etag.index(etag.startIndex, offsetBy: 2) : etag.startIndex
        let tagValue = etag[startIndex...]
        let stripped = tagValue.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        return Int(stripped) ?? 0
    }
}
