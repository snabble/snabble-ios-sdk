//
//  Telecash.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

// response object for the `telecashVaultItems` endpoint (POST w/empty body)
public struct TelecashVaultItem: Decodable {
    public let chargeTotal: String
    public let currency: String
    public let date: String
    public let hash: String
    public let links: TelecashVaultItemLinks
    public let orderId: String
    public let storeId: String
    public let url: String // DELETE this to cancel the pre-auth

    public struct TelecashVaultItemLinks: Decodable {
        public let `self`: Link
    }
}
