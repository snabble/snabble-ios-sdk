//
//  CouponManager.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

struct CouponEntry: Codable {
    let coupon: Coupon
    var active: Bool // true -> add this coupon to the next shopping cart created for the corresponding project

    init(coupon: Coupon) {
        self.coupon = coupon
        self.active = false
    }
}

final class CouponWallet {
    static let shared = CouponWallet()

    private(set) var coupons = [CouponEntry]()

    private init() {
        self.coupons = load()
    }

    func contains(_ coupon: Coupon) -> Bool {
        return coupons.firstIndex(where: { $0.coupon == coupon }) != nil
    }

    func add(_ coupon: Coupon) {
        if !contains(coupon) {
            coupons.append(CouponEntry(coupon: coupon))
            save()
        }
    }

    func remove(_ coupon: Coupon) {
        coupons.removeAll { $0.coupon == coupon }
        save()
    }

    func activate(_ coupon: Coupon, active: Bool = true) {
        if let index = coupons.firstIndex(where: { $0.coupon == coupon }) {
            coupons[index].active = active
            save()
        }
    }

    func removeUnknowns(_ list: [Coupon]) {
        coupons.removeAll {
            !list.contains($0.coupon)
        }
    }

    func active(for projectId: Identifier<Project>) -> [Coupon] {
        return coupons
            .filter { $0.coupon.projectID == projectId }
            .map { $0.coupon }
    }

    // for testing only!
    func addAll(_ list: [Coupon]) {
        list.forEach { add($0) }
    }
}

// MARK: - Persistence
extension CouponWallet {
    private var url: URL {
        let fileManager = FileManager.default
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("coupons.json")
    }

    /// persist coupons to disk
    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(self.coupons)
            try data.write(to: url, options: .atomic)
        } catch let error {
            Log.error("error saving coupons: \(error)")
        }
    }

    /// load coupons from disk
    private func load() -> [CouponEntry] {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let entries = try JSONDecoder().decode([CouponEntry].self, from: data)
            return entries
        } catch let error {
            Log.error("error loading coupons: \(error)")
            return []
        }
    }
}
