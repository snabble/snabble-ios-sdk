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

    public let code: String? // the code to render in-app
    public let codes: [Code]? // the scannable codes for this coupon

    #warning("FIXME - remove optional")
    public let projectID: Identifier<Project>?

    // cms properties
    public let colors: Colors?
    public let description: String?
    public let promotionDescription: String?
    public let disclaimer: String?
    public let image: Image?
    public let validFrom: Date?
    public let validUntil: Date?
    public let percentage: Int?

    public struct Code: Codable {
        public let code, template: String
    }

    public struct Colors: Codable {
        public let background, foreground: String
    }

    // MARK: - Image
    public struct Image: Codable {
        public let formats: [Format]
        public let name: String
    }

    // MARK: - Format
    public struct Format: Codable {
        public let contentType: String
        public let height: Int
        public let size: String
        public let url: URL
        public let width: Int
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
