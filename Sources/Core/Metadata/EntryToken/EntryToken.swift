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
    func getEntryToken(for shopID: Identifier<Shop>, completion: @escaping (Result<SnabbleCore.EntryToken, SnabbleError>) -> Void) {
        getWanzelEntryToken(for: shopID) { result in
            switch result {
            case .success(let token):
                completion(.success(token))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
