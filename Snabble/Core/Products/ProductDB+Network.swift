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

    private static let sqlType = "application/vnd+snabble.appdb+sql"
    private static let sqliteType = "application/vnd+snabble.appdb+sqlite3"
    private static let contentTypes = "\(sqlType),\(sqliteType)"

    func getAppDb(currentRevision: Int64, schemaVersion: String, forceFullDb: Bool = false, completion: @escaping (AppDbResponse) -> () ) {
        let start = Date.timeIntervalSinceReferenceDate

        let parameters = [
            "havingRevision": "\(currentRevision)",
            "schemaVersion": schemaVersion
        ]

        self.project.request(.get, self.project.links.appdb.href, json: false, parameters: parameters, timeout: 0) { request in
            guard var request = request else {
                return completion(.httpError)
            }

            request.setValue(ProductDB.contentTypes, forHTTPHeaderField: "Accept")
            let session = SnabbleAPI.urlSession()

            let task = session.dataTask(with: request) { data, response, error in
                let elapsed = Date.timeIntervalSinceReferenceDate - start
                let url = request.url?.absoluteString ?? "n/a"
                Log.info("get \(url) took \(elapsed)s")

                if error != nil {
                    completion(.httpError)
                    return
                }

                if let data = data, let response = response as? HTTPURLResponse {
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
            task.resume()
        }
    }

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
