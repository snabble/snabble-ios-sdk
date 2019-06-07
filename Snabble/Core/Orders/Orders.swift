//
//  Orders.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

struct OrderList: Decodable {
    let orders: [Order]
}

struct Order: Decodable {
    let project: String
    let id: String
    let date: Date
    let shopId: String
    let shopName: String
    let price: Int
    let links: OrderLinks

    enum CodingKeys: String, CodingKey {
        case project, id, date, shopName, price, links
        case shopId = "shopID"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.project = try container.decode(String.self, forKey: .project)
        self.id = try container.decode(String.self, forKey: .id)
        let date = try container.decode(String.self, forKey: .date)
        let formatter = ISO8601DateFormatter()
        if #available(iOS 11.2, *) {
            formatter.formatOptions.insert(.withFractionalSeconds)
        }
        self.date = formatter.date(from: date) ?? Date()

        self.shopId = try container.decode(String.self, forKey: .shopId)
        self.shopName = try container.decode(String.self, forKey: .shopName)
        self.price = try container.decode(Int.self, forKey: .price)
        self.links = try container.decode(.links, as: OrderLinks.self)
    }
}

struct OrderLinks: Decodable {
    let receipt: Link
}

struct ClientOrders {

    static func loadList(completion: @escaping (Result<OrderList, SnabbleError>)->() ) {
        let url = SnabbleAPI.links.clientOrders.href.replacingOccurrences(of: "{clientID}", with: SnabbleAPI.clientId)

        let project = SnabbleAPI.projects[0]
        project.request(.get, url, timeout: 0) { request in
            guard let request = request else {
                return completion(Result.failure(SnabbleError.noRequest))
            }

            project.perform(request) { (result: Result<OrderList, SnabbleError>) in
                completion(result)
            }
        }
    }

}
