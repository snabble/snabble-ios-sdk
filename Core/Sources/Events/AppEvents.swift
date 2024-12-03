//
//  AppEvents.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import Foundation

enum EventType: String, Encodable {
    case sessionStart
    case sessionEnd
    case cart
    case error
    case log
    case analytics
    case productNotFound
}

private struct Session: Encodable {
    let session: String
}

private struct Message: Encodable {
    let message: String
    let session: String?
}

private struct Analytics: Encodable {
    let key: String
    let value: String
    let comment: String
}

private struct ProductNotFound: Encodable {
    let scannedCode: String
    let matched: [String: String]
}

private enum Payload: Encodable {
    case session(Session)
    case error(Message)
    case cart(Cart)
    case log(Message)
    case analytics(Analytics)
    case productNotFound(ProductNotFound)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .session(let session): try container.encode(session)
        case .error(let msg): try container.encode(msg)
        case .log(let msg): try container.encode(msg)
        case .cart(let cart): try container.encode(cart)
        case .analytics(let analytics): try container.encode(analytics)
        case .productNotFound(let notFound): try container.encode(notFound)
        }
    }
}

public struct AppEvent: Encodable {
    private let type: EventType
    private let appId: String
    private let payload: Payload
    private let projectId: Identifier<Project>
    private let timestamp: Date

    private let shopId: Identifier<Shop>?
    private let id: String?
    private let agent: String?

    private let project: Project

    enum CodingKeys: String, CodingKey {
        case type, appId, payload, timestamp
        case projectId = "project"
        case shopId, id, agent
    }

    private init(type: EventType, payload: Payload, project: Project,
                 shopId: Identifier<Shop>? = nil, id: String? = nil, agent: String? = nil) {
        self.type = type
        self.appId = Snabble.clientId
        self.payload = payload
        self.shopId = shopId
        self.project = project
        self.projectId = project.id
        self.id = id
        self.agent = agent
        self.timestamp = Date()
    }

    init(_ type: EventType, session: String, project: Project, shopId: Identifier<Shop>? = nil) {
        assert(type == .sessionStart || type == .sessionEnd, "session events must have a session type")
        let session = Payload.session(Session(session: session))
        self.init(type: type, payload: session, project: project, shopId: shopId)
    }

    public init(error: String, project: Project, session: String? = nil, shopId: Identifier<Shop>? = nil) {
        let error = Payload.error(Message(message: error, session: session))
        self.init(type: .error, payload: error, project: project, shopId: shopId)
    }

    public init(log: String, project: Project, session: String? = nil, shopId: Identifier<Shop>? = nil) {
        let log = Payload.log(Message(message: log, session: session))
        self.init(type: .log, payload: log, project: project, shopId: shopId)
    }

    public init(key: String, value: String, comment: String = "", project: Project, shopId: Identifier<Shop>? = nil) {
        let analytics = Payload.analytics(Analytics(key: key, value: value, comment: comment))
        self.init(type: .analytics, payload: analytics, project: project, shopId: shopId)
    }

    public init?(_ shoppingCart: ShoppingCart) {
        let cart = shoppingCart.createCart()
        guard let project = Snabble.shared.project(for: shoppingCart.projectId) else {
            return nil
        }

        self.init(type: .cart, payload: Payload.cart(cart), project: project, shopId: shoppingCart.shopId)
    }

    public init(scannedCode: String, codes: [(String, String)], project: Project) {
        var dict = [String: String]()
        for (code, template) in codes {
            dict[template] = code
        }

        let notFound = Payload.productNotFound(ProductNotFound(scannedCode: scannedCode, matched: dict))
        self.init(type: .productNotFound, payload: notFound, project: project)
    }
}

extension AppEvent {
    public func post() {
        // use URLRequest/URLSession directly to avoid error logging loops when posting the event fails
        guard let url = Snabble.shared.urlFor(self.project.links.appEvents.href) else {
            return
        }
        guard let token = Snabble.shared.tokenRegistry.getExistingToken(for: self.project) else {
            return
        }

        var request = Snabble.request(url: url, json: true)
        request.httpMethod = "POST"

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(self)
            request.addValue(token, forHTTPHeaderField: "Client-Token")
        } catch {
            Log.error("\(error)")
        }

        let task = URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                Log.error("posting event failed: \(error)")
            }
        }
        task.resume()
    }
}

public enum RatingEvent {
    public static func track(_ project: Project, _ value: Int, _ comment: String?, _ shopId: Identifier<Shop>?) {
        let event = AppEvent(key: "rating", value: "\(value)", comment: comment ?? "", project: project, shopId: shopId)
        event.post()
    }
}
