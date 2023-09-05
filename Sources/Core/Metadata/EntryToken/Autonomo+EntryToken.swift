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

    public struct EntryToken: Codable, SnabbleCore.EntryToken {
        public let value: String
        public let validUntil: Date
        public let refreshAfter: Date
    }
}

private struct SessionRequest: Encodable {
    let shopID: String
    let paymentMethod: String
    let paymentOrigin: String
}

extension Project {
    public func getAutonomoSession(for shop: Shop, paymentMethodDetail: PaymentMethodDetail, completion: @escaping (Result<Autonomo.Session, SnabbleError>) -> Void) {
        let tokenRequest = SessionRequest(
            shopID: shop.id.rawValue,
            paymentMethod: paymentMethodDetail.rawMethod.rawValue,
            paymentOrigin: paymentMethodDetail.encryptedData
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
