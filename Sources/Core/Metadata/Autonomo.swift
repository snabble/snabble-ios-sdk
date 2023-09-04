//
//  Autonomo.swift
//
//
//  Created by Andreas Osberghaus on 2023-09-04.
//

import Foundation

public enum Autonomo {
    public struct Session: Codable {
        public let id: String
        public let entryToken: EntryToken
    }

    public struct EntryToken: Codable {
        public let value: String
        public let validUntil: Date
        public let refreshAfter: Date
        public let format: ScanFormat = .qr

        public init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<Autonomo.EntryToken.CodingKeys> = try decoder.container(keyedBy: Autonomo.EntryToken.CodingKeys.self)
            self.value = try container.decode(String.self, forKey: Autonomo.EntryToken.CodingKeys.value)
            self.validUntil = try container.decode(Date.self, forKey: Autonomo.EntryToken.CodingKeys.validUntil)
            self.refreshAfter = try container.decode(Date.self, forKey: Autonomo.EntryToken.CodingKeys.refreshAfter)
        }
    }
}

private struct SessionRequest: Encodable {
    let shopID: Identifier<Shop>
    let paymentMethod: String
    let paymentOrigin: String
}

extension Project {
    public func getAutonomoSession(for shop: Shop, paymentMethod: PaymentMethod, completion: @escaping (Result<Autonomo.EntryToken, SnabbleError>) -> Void) {
        guard let data = paymentMethod.data?.encryptedData else {
            return completion(.failure(SnabbleError.invalid))
        }

        let tokenRequest = SessionRequest(
            shopID: shop.id,
            paymentMethod: paymentMethod.rawMethod.rawValue,
            paymentOrigin: data
        )

        guard let data = try? JSONEncoder().encode(tokenRequest) else {
            return completion(.failure(SnabbleError.invalid))
        }

        self.request(.post, "/\(shop.projectId)/autonomo/sessions", body: data, timeout: 5) { request in
            guard let request = request else {
                return completion(.failure(SnabbleError.noRequest))
            }

            self.perform(request, completion)
        }
    }
}
