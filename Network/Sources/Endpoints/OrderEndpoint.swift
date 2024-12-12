//
//  ReceiptsEndpoint.swift
//  Snabble
//
//  Created by Andreas Osberghaus on 2024-11-04.
//

import Foundation

extension Endpoints {
    public enum Order {
        private static var jsonDecoder: JSONDecoder {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            return decoder
        }
        
        private static func path(forAppUserId appUserId: String) -> String {
            "/apps/users/\(appUserId)/orders"
        }
        
        public static func get(forAppUserId appUserId: String) -> Endpoint<[SnabbleNetwork.Order]> {
            return .init(
                path: path(forAppUserId: appUserId),
                method: .get(nil),
                parse: { data in
                    try jsonDecoder.decode(SnabbleNetwork.Orders.self, from: data).orders
                }
            )
        }
        
        public enum Receipts {
            public static func receipt(forOrder order: SnabbleNetwork.Order) -> Endpoint<Data> {
                receipt(forTransactionId: order.id, withProjectId: order.projectId)
            }
            
            public static func receipt(forTransactionId transactionId: String, withProjectId projectId: String) -> Endpoint<Data> {
                return .init(
                    path: "/\(projectId)/orders/id/\(transactionId)/receipt",
                    method: .get(nil),
                    parse: { data in
                        data
                    }
                )
            }
        }
    }
}
