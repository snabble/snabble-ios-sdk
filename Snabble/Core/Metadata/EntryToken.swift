//
//  EntryToken.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public struct EntryToken: Decodable {
    public let format: String
    public let value: String
    #warning("FIXME: date format default?")
    public let validUntil: String
}

extension Project {
    public func getEntryToken(completion: @escaping (Result<EntryToken, SnabbleError>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let date = Date(timeIntervalSinceNow: 100)
            let token = EntryToken(format: "qr",
                                   value: "\(UUID().uuidString)",
                                   validUntil: Snabble.iso8601Formatter.string(from: date))
            completion(.success(token))
        }
    }

    public func getEntryToken2(completion: @escaping (Result<EntryToken, SnabbleError>) -> Void) {
        guard let url = links.entryToken?.href else {
            return completion(.failure(SnabbleError.invalid))
        }

        self.request(.post, url, timeout: 2) { request in
            guard let request = request else {
                return completion(.failure(SnabbleError.noRequest))
            }

            self.perform(request) { (_ result: Result<EntryToken, SnabbleError>) in
                completion(result)
            }
        }
    }
}
