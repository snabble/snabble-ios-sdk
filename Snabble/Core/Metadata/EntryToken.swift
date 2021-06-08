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

private struct EntryTokenRequest: Encodable {
    let shopID: Identifier<Shop>
}

extension Project {
    public func getEntryToken(for shopId: Identifier<Shop>, completion: @escaping (Result<EntryToken, SnabbleError>) -> Void) {
        let tokenRequest = EntryTokenRequest(shopID: shopId)

        guard
            let url = links.entryToken?.href,
            let data = try? JSONEncoder().encode(tokenRequest)
        else {
            return completion(.failure(SnabbleError.invalid))
        }

        self.request(.post, url, body: data, timeout: 2) { request in
            guard let request = request else {
                return completion(.failure(SnabbleError.noRequest))
            }

            self.perform(request, completion)
        }
    }
}
