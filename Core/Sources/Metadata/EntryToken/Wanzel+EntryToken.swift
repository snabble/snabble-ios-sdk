//
//  EntryToken.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public enum Wanzel {
    public struct EntryToken: Decodable, SnabbleCore.EntryToken, Sendable {
        public let value: String
        public let validUntil: Date
        public let refreshAfter: Date

        enum CodingKeys: CodingKey {
            case value
            case validUntil
        }

        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<Wanzel.EntryToken.CodingKeys> = try decoder.container(keyedBy: Wanzel.EntryToken.CodingKeys.self)
            self.value = try container.decode(String.self, forKey: Wanzel.EntryToken.CodingKeys.value)
            self.validUntil = try container.decode(Date.self, forKey: Wanzel.EntryToken.CodingKeys.validUntil)
            self.refreshAfter = validUntil.addingTimeInterval(-10)
        }
    }
}

private struct EntryTokenRequest: Encodable, Sendable {
    let shopID: Identifier<Shop>
}

extension Project {
    public func getWanzelEntryToken(for shopId: Identifier<Shop>, completion: @escaping @Sendable (Result<Wanzel.EntryToken, SnabbleError>) -> Void) {
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
