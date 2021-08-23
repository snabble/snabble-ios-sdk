//
//  Coupon.swift
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

    public let projectID: Identifier<Project>

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
        public let code: String
        public let template: String
    }
}

public struct Colors: Codable {
    public let background: String
    public let foreground: String
}

public struct Image: Codable {
    public let formats: [Format]
    public let name: String
}

public struct Format: Codable {
    public let height: Int
    public let size: String
    public let url: URL
    public let width: Int
}

extension Coupon: Equatable {
    public static func == (lhs: Coupon, rhs: Coupon) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct CouponList: Decodable {
    let coupons: [Coupon]
}
