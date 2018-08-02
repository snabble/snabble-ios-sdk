//
//  AppEvents.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import Foundation

enum EventType: String, Encodable {
    case sessionStart
    case sessionEnd
    case cart
    case error
}

struct Session: Encodable {
    let session: String
}

struct Error: Encodable {
    let message: String
    let session: String?
}

enum Payload: Encodable {
    case session(Session)
    case error(Error)
    case cart(Cart)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .session(let session): try container.encode(session)
        case .error(let error): try container.encode(error)
        case .cart(let cart): try container.encode(cart)
        }
    }
}

struct AppEvent: Encodable {
    let type: EventType
    let appId: String
    let payload: Payload
    let project: String
    let timestamp: String

    let shopId: String?
    let id: String?
    let agent: String?

    private init(type: EventType, payload: Payload,
                     shopId: String? = nil, id: String? = nil,
                     agent: String? = nil) {
        self.type = type
        self.appId = APIConfig.shared.clientId
        self.payload = payload
        self.shopId = shopId
        self.project = APIConfig.shared.project.id
        self.id = id
        self.agent = agent
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        self.timestamp = fmt.string(from: Date())
    }

    init(_ type: EventType, session: String, shopId: String? = nil) {
        assert(type == .sessionStart || type == .sessionEnd, "session events must have a session type")
        let session = Payload.session(Session(session: session))
        self.init(type: type, payload: session, shopId: shopId)
    }

    init(message: String, session: String? = nil, shopId: String? = nil) {
        let error = Payload.error(Error(message: message, session: session))
        self.init(type: .error, payload: error, shopId: shopId)
    }

    init(_ shoppingCart: ShoppingCart) {
        let cart = shoppingCart.createCart()
        self.init(type: .cart, payload: Payload.cart(cart), shopId: cart.shopID)
    }

}

extension AppEvent {

    struct Empty: Decodable { }

    func post() {
        let appEvents = APIConfig.shared.project.links.appEvents.href
        guard
            let request = SnabbleAPI.request(.post, appEvents, body: self, timeout: 0)
        else {
            return
        }

        // NSLog("posting event \(String(describing: self))")
        SnabbleAPI.perform(request) { (result: Empty?, error) in
            if let error = error {
                NSLog("error posting event: \(error)")
            }
        }
    }

}
