//
//  EntryToken.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public struct EntryToken: Decodable {
    public let format: ScanFormat
    public let value: String
    public let validUntil: Date
}

extension Project {

    // mock
    public func getEntryToken(completion: @escaping (Result<EntryToken, SnabbleError>) -> Void) {
        let date = Date(timeIntervalSinceNow: 100)
        let unixTime = Int(Date().timeIntervalSince1970)
        let value = "snabble:qr:\(UUID().uuidString):\(unixTime)"
        let json = """
        {"format": "qr", "value": "\(value)", "validUntil": "\(Formatter.iso8601.string(from: date))"}
        """.data(using: .utf8)!

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .customISO8601
            // swiftlint:disable:next force_try
            let token = try! decoder.decode(EntryToken.self, from: json)
            completion(.success(token))
        }
    }

//    public func getEntryToken(completion: @escaping (Result<EntryToken, SnabbleError>) -> Void) {
//        guard let url = links.entryToken?.href else {
//            return completion(.failure(SnabbleError.invalid))
//        }
//
//        self.request(.post, url, timeout: 2) { request in
//            guard let request = request else {
//                return completion(.failure(SnabbleError.noRequest))
//            }
//
//            self.perform(request) { (_ result: Result<EntryToken, SnabbleError>) in
//                completion(result)
//            }
//        }
//    }
}
