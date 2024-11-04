//
//  ReceiptsEndpoint.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-11-04.
//

import Foundation

extension Endpoints {
    public enum Order {
        public static func get(forAppUserId appUserId: String) -> Endpoint<[SnabbleNetwork.Order]> {
            return .init(
                path: "/apps/users/\(appUserId)/orders",
                method: .get(nil),
                parse: { data in
                    try Endpoints.jsonDecoder.decode([SnabbleNetwork.Order].self, from: data)
                }
            )
        }
        
        public static func get(forAppUserId appUserId: String, filteredByProjectId projectId: String) -> Endpoint<[SnabbleNetwork.Order]> {
            return .init(
                path: "/apps/users/\(appUserId)/orders",
                method: .get(nil),
                parse: { data in
                    try Endpoints.jsonDecoder.decode([SnabbleNetwork.Order].self, from: data)
                        .filter { $0.projectId == projectId }
                }
            )
        }
        
        public static func get(forAppUserId appUserId: String, filteredByProjectId projectId: String, andShopId shopId: String) -> Endpoint<[SnabbleNetwork.Order]> {
            return .init(
                path: "/apps/users/\(appUserId)/orders",
                method: .get(nil),
                parse: { data in
                    try Endpoints.jsonDecoder.decode([SnabbleNetwork.Order].self, from: data)
                        .filter { $0.projectId == projectId }
                        .filter { $0.shopId == shopId }
                }
            )
        }
        
        enum Receipts {
            public static func receipt(forOrder order: SnabbleNetwork.Order) -> Endpoint<URL> {                
                return .init(
                    path: order.receiptPath,
                    method: .get(nil),
                    parse: {
                        try order.saveReceipt(forData: $0)
                    }
                )
            }
        }
    }
}
