//
//  CouponManager.swift
//
//  Copyright © 2021 snabble. All rights reserved.
//

import Foundation

public enum CouponType: String, Codable, UnknownCaseRepresentable {
    case unknown

    case manual
    case printed
    case digital

    public static var unknownCase = CouponType.unknown
}

public struct Coupon: Codable {
    public let id: String
    public let name: String
    public let type: CouponType

    public let codes: [Code]?
    public let projectID: Identifier<Project>

    public struct Code: Codable {
        public let code, template: String
    }
}

extension Coupon: Equatable {
    public static func == (lhs: Coupon, rhs: Coupon) -> Bool {
        return lhs.id == rhs.id
    }
}

struct CouponEntry: Codable {
    let coupon: Coupon
    var active: Bool // true -> add this coupon to the next shopping cart created for the corresponding project

    init(coupon: Coupon) {
        self.coupon = coupon
        self.active = false
    }
}

class CouponManager {
    static let shared = CouponManager()

    private(set) var coupons = [CouponEntry]()

    private init() {
        self.coupons = load()
    }

    func add(_ coupon: Coupon) {
        if coupons.firstIndex(where: { $0.coupon == coupon }) == nil {
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

    // for testing only!
    func addAll(_ list: [Coupon]) {
        list.forEach { add($0) }
    }
}

// MARK: - Persistence
extension CouponManager {
    private var url: URL {
        let fileManager = FileManager.default
        return fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("coupons.json")
    }

    /// persist coupons to disk
    private func save() {
        do {
            let data = try JSONEncoder().encode(self.coupons)
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
