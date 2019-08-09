//
//  OfflineCarts.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

/// manages storage of carts where creation of the checkout info / checkout process failed.
/// it is the hosting app's responsibiliy to attempt to retry posting this data to the backend
/// e.g. when it discovers that internet connectivity is restored

public class OfflineCarts {

    static let shared = OfflineCarts()

    private var savedCarts = [ShoppingCart]()

    private init() {
        self.savedCarts = self.readSavedCarts()
    }

    // append a shopping cart to the list of carts that need to be sent later
    func saveCartForLater(_ cart: ShoppingCart) {
        synchronized(self) {
            self.savedCarts.append(cart)
            self.writeSavedCarts(self.savedCarts)
        }
    }

    func retrySendingCarts() {
        let carts = synchronized(self) {
            return self.savedCarts
        }

        let group = DispatchGroup()
        var successIndices = [Int]()

        // retry the requests
        for (index, cart) in carts.enumerated() {
            guard let project = SnabbleAPI.projectFor(cart.projectId) else {
                continue
            }

            group.enter()
            cart.createCheckoutInfo(project) { result in
                switch result {
                case .success(let info):
                    info.createCheckoutProcess(project, paymentMethod: .qrCodeOffline, processedOffline: true) { result in
                        switch result {
                        case .success:
                            synchronized(self) {
                                successIndices.append(index)
                            }
                        case .failure(let error):
                            #warning("if it's a client error (HTTP 4xx), add the index to the 'remove' array")
                            Log.error("error creating process: \(error)")
                        }
                        group.leave()
                    }
                case .failure(let error):
                    Log.error("error creating info: \(error)")
                    group.leave()
                }
            }
        }

        // wait for all responses
        group.wait()

        // remove all carts where the re-sending was successful
        synchronized(self) {
            let indices = successIndices.sorted(by: >)
            indices.forEach {
                self.savedCarts.remove(at: $0)
            }
            self.writeSavedCarts(self.savedCarts)
        }
    }
}

// MARK: - persistence
extension OfflineCarts {

    func readSavedCarts() -> [ShoppingCart] {
        return []
    }

    func writeSavedCarts(_ carts: [ShoppingCart]) {

    }
}
