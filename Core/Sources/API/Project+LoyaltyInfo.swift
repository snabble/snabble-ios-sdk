//
//  Project+LoyaltyInfo.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public struct CustomerLoyaltyInfo: Decodable, Sendable {
    public let loyaltyCardNumber: String
}

public struct CustomerLoyaltyCredentials: Encodable, Sendable {
    public let username: String
    public let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

extension Project {
    public func getCustomerLoyaltyInfo(with credentials: CustomerLoyaltyCredentials,
                                       completion: @escaping @Sendable (Result<CustomerLoyaltyInfo, SnabbleError>) -> Void) {
        guard let url = self.links.customerLoyaltyInfo?.href else {
            return completion(.failure(.noRequest))
        }

        do {
            let data = try JSONEncoder().encode(credentials)

            self.request(.post, url, body: data, timeout: 2) { request in
                guard let request = request else {
                    return completion(.failure(SnabbleError.noRequest))
                }

                self.perform(request, completion)
            }
        } catch {
            print(error)
            completion(.failure(SnabbleError.invalid))
        }
    }
}
