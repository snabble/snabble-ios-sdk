//
//  ReceiptsManager.swift
//
//  Copyright © 2018 snabble. All rights reserved.
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
        self.date = formatter.date(from: date) ?? Date()
        #warning("remove optionals")
        self.shopId = (try container.decodeIfPresent(String.self, forKey: .shopId)) ?? "1"
        self.shopName = (try container.decodeIfPresent(String.self, forKey: .shopName)) ?? "Shopname"
        self.price = (try container.decodeIfPresent(Int.self, forKey: .price)) ?? 42
        self.links = try container.decode(.links, as: OrderLinks.self)
    }
}

struct OrderLinks: Decodable {
    let receipt: Link
}

struct ClientOrders {

    static func loadList(completion: @escaping (OrderList?)->() ) {
        let url = SnabbleAPI.links.clientOrders.href.replacingOccurrences(of: "{clientID}", with: SnabbleAPI.clientId)

        let project = SnabbleAPI.projects[0]
        project.request(.get, url, timeout: 0) { request in
            guard let request = request else {
                return completion(nil)
            }

            project.perform(request) { (result: OrderList?, error) in
                completion(result)
            }
        }
    }

}
