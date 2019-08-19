//
//  OfflineCarts.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import Foundation

/// manages storage of carts where creation of the checkout info and/or checkout process failed.
/// it is the hosting app's responsibiliy to attempt to retry posting this data to the backend
/// e.g. when it discovers that internet connectivity is restored

struct SavedCart: Codable {
    let cart: ShoppingCart
    var failures: Int

    init(_ cart: ShoppingCart) {
        self.cart = cart
        self.failures = 0
    }
}

public class OfflineCarts {

    public static let shared = OfflineCarts()

    private var savedCarts = [SavedCart]()
    private var inProgress = false

    private init() {
        self.savedCarts = self.readSavedCarts()
    }

    /// append a shopping cart to the list of carts that need to be sent later
    func saveCartForLater(_ cart: ShoppingCart) {
        synchronized(self) {
            self.savedCarts.append(SavedCart(cart))
            self.writeSavedCarts(self.savedCarts)
        }
    }

    public var retryNeeded: Bool {
        return self.savedCarts.count > 0
    }

    /// retry sending saved carts to the backend
    public func retrySendingCarts() {
        guard !self.inProgress && self.savedCarts.count > 0 else {
            return
        }
        self.inProgress = true

        DispatchQueue.global(qos: .background).async {
            self.doRetrySendingCarts()
        }
    }

    private func doRetrySendingCarts() {
        let carts = synchronized(self) {
            return self.savedCarts
        }

        let group = DispatchGroup()
        var successIndices = [Int]()

        // retry the requests
        for (index, savedCart) in carts.enumerated() {
            let cart = savedCart.cart
            guard let project = SnabbleAPI.projectFor(cart.projectId) else {
                continue
            }

            group.enter()
            cart.createCheckoutInfo(project, timeout: 2) { result in
                switch result {
                case .success(let info):
                    info.createCheckoutProcess(project, paymentMethod: .qrCodeOffline, processedOffline: true) { result in
                        switch result {
                        case .success:
                            synchronized(self) {
                                successIndices.append(index)
                            }
                        case .failure(let error):
                            self.savedCarts[index].failures += 1
                            Log.error("error creating process: \(error)")
                        }
                        group.leave()
                    }
                case .failure(let error):
                    self.savedCarts[index].failures += 1
                    Log.error("error creating info: \(error)")
                    group.leave()
                }
            }
        }

        // wait for all responses
        group.wait()

        // remove all carts where the re-sending was successful or we had too many failures
        synchronized(self) {
            for i in (0..<self.savedCarts.count).reversed() {
                if successIndices.contains(i) || self.savedCarts[i].failures > 3 {
                    self.savedCarts.remove(at: i)
                }
            }
            self.writeSavedCarts(self.savedCarts)
        }
        self.inProgress = false
    }
}

// MARK: - persistence
extension OfflineCarts {

    private func url() -> URL {
        let fileManager = FileManager.default
        let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        if !fileManager.fileExists(atPath: appSupportDir.path) {
            try? fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true, attributes: nil)
        }

        return appSupportDir.appendingPathComponent("savedCarts.json")
    }

    func readSavedCarts() -> [SavedCart] {
        do {
            let data = try Data(contentsOf: self.url())
            return try JSONDecoder().decode([SavedCart].self, from: data)
        } catch {
            Log.error("saved carts: read failed \(error)")
            return []
        }
    }

    func writeSavedCarts(_ carts: [SavedCart]) {
        do {
            let data = try JSONEncoder().encode(self.savedCarts)
            try data.write(to: self.url(), options: .atomic)
        } catch {
            Log.error("saved carts: write failed \(error)")
        }
    }
}
