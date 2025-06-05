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
            let decoder = JSONDecoder()

            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)

                let formats = [
                    "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ",
                    "yyyy-MM-dd'T'HH:mm:ssZ"
                ]

                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)

                for format in formats {
                    formatter.dateFormat = format
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                }

                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Date string does not match expected formats."
                )
            }
            return decoder
        }
        
        public static func get() -> Endpoint<[SnabbleNetwork.Order]> {
            return .init(
                path: "/apps/users/me/orders",
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
