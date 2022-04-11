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

    struct InFlightCheckout: Codable {
        let url: String
        let shop: Shop
        let cart: ShoppingCart
    }

    static func storeInFlightCheckout(url: String, shop: Shop, cart: ShoppingCart) {
        let inflight = InFlightCheckout(url: url, shop: shop, cart: cart)
        do {
            let data = try JSONEncoder().encode(inflight)
            UserDefaults.standard.set(data, forKey: Self.inFlightKey)
        } catch {
            print("error storing in-flight checkout: \(error)")
        }
    }

    static func clearInFlightCheckout() {
        print(#function)
        UserDefaults.standard.removeObject(forKey: Self.inFlightKey)
    }

    static var inFlightCheckout: InFlightCheckout? {
        print(#function)
        guard let data = UserDefaults.standard.data(forKey: Self.inFlightKey) else {
            return nil
        }

        do {
            let inFlight = try JSONDecoder().decode(InFlightCheckout.self, from: data)
            return inFlight
        } catch {
            print("error decoding in-flight checkout: \(error)")
            return nil
        }
    }

    public static var isInFlightCheckoutPending: Bool {
        UserDefaults.standard.data(forKey: Self.inFlightKey) != nil
    }
}
