//
//  Snabble+Inflight.swift
//  Snabble
//
//  Created by Gereon Steffens on 11.04.22.
//

import Foundation

// MARK: - in-flight checkout process
extension Snabble {
    static let inFlightKey = "io.snabble.inFlightCheckout"

    public struct InFlightCheckout: Codable, Sendable {
        public let url: String
        public let shop: Shop
        public let cart: ShoppingCart
    }

    public static func storeInFlightCheckout(url: String, shop: Shop, cart: ShoppingCart) {
        let inflight = InFlightCheckout(url: url, shop: shop, cart: cart)
        do {
            let data = try JSONEncoder().encode(inflight)
            UserDefaults.standard.set(data, forKey: Self.inFlightKey)
        } catch {
            print("error storing in-flight checkout: \(error)")
        }
    }

    public static func clearInFlightCheckout() {
        UserDefaults.standard.removeObject(forKey: Self.inFlightKey)
        UserDefaults.standard.synchronize()
    }

    public static var inFlightCheckout: InFlightCheckout? {
        guard let data = UserDefaults.standard.data(forKey: Self.inFlightKey) else {
            return nil
        }

        do {
            return try JSONDecoder().decode(InFlightCheckout.self, from: data)
        } catch {
            print("error decoding in-flight checkout: \(error)")
            return nil
        }
    }

    public static var isInFlightCheckoutPending: Bool {
        UserDefaults.standard.data(forKey: Self.inFlightKey) != nil
    }
}
