//
//  EntryToken.swift
//
//
//  Created by Andreas Osberghaus on 2023-09-05.
//

import Foundation

public protocol EntryToken: Codable {
    var value: String { get }
    var validUntil: Date { get }
    var refreshAfter: Date { get }
}

public extension Project {
    func getEntryToken(for shop: Shop, paymentMethodDetail: PaymentMethodDetail?, completion: @escaping (Result<SnabbleCore.EntryToken, SnabbleError>) -> Void) {
        if shop.isGrabAndGo {
            guard let paymentMethodDetail else {
                return completion(.failure(SnabbleError.noRequest))
            }
            getAutonomoSession(for: shop, paymentMethodDetail: paymentMethodDetail) { result in
                switch result {
                case .success(let session):
                    completion(.success(session.entryToken))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            getWanzelEntryToken(for: shop.id) { result in
                switch result {
                case .success(let token):
                    completion(.success(token))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
