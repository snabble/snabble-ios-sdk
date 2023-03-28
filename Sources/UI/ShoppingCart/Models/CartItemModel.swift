//
//  CartItemModel.swift
//  
//
//  Created by Uwe Tilemann on 14.03.23.
//

import Foundation
import Combine
import SnabbleCore
import SwiftUI

public protocol ShoppingCartItem: Swift.Identifiable {
    var id: String { get }
    var title: String { get }
    var leftDisplay: LeftDisplay { get }
    var rightDisplay: RightDisplay { get }
    var image: SwiftUI.Image? { get }
    var showImages: Bool { get set }
}

public protocol ShoppingCartItemCounting {
    var quantity: Int { get set }
}

public protocol ShoppingCartItemDiscounting: Swift.Identifiable {
    var discount: Int { get }
    var name: String { get }
}

public struct ShoppingCartItemDiscount: ShoppingCartItemDiscounting {
    public enum DiscountType: String {
        case unknown
        case priceModifier
        case discountedProduct = "discounted_product"
        case totalDiscount = "total-discount"
    }
    public let id = UUID().uuidString
    
    public var discount: Int
    public var name: String
    public var type: DiscountType
    
    init(discount: Int, name: String? = nil, type: DiscountType = .unknown) {
        self.discount = discount
        self.name = name ?? "Discount"
        self.type = type
    }
    init(discount: Int, name: String? = nil, type: String? = nil) {
        self.discount = discount
        self.name = name ?? "Discount"
        self.type = .unknown
        if let typeString = type {
            if let discountType = DiscountType(rawValue: typeString) {
                self.type = discountType
            } else {
                print("unknown discountType \(name ?? "n/a"): \(typeString)")
            }
        }
    }
}

public protocol ShoppingCartItemPricing {
    var regularPrice: Int { get }
    var discounts: [ShoppingCartItemDiscount] { get }
    var formatter: PriceFormatter { get }
}

public extension ShoppingCartItemPricing {
    var hasDiscount: Bool {
        return !discounts.isEmpty
    }

    var totalDiscount: Int {
        let totalDiscount = discounts.reduce(0, { $0 + $1.discount })
        return totalDiscount
    }
    var reducedPrice: Int {
        guard hasDiscount else {
            return regularPrice
        }
        return regularPrice + totalDiscount
    }
}

public extension ShoppingCartItemPricing {
    
    var reducedPriceString: String {
        return formatter.format(reducedPrice)
    }

    var regularPriceString: String? {
        let price = self.regularPrice
        guard price != 0 else {
            return nil
        }
        return formatter.format(price)
    }
}

public protocol ShoppingCartItemBadging {
    var badgeText: String? { get }
}

public extension ShoppingCartItemBadging {
    var badgeColor: ColorStyle {
        return .systemRed
    }
}

open class CartItemModel: ObservableObject, ShoppingCartItem {
    public var id: String {
        return UUID().uuidString
    }
    
    @Published public var title: String
    @Published public var leftDisplay: LeftDisplay
    @Published public var rightDisplay: RightDisplay

    @Published public var image: SwiftUI.Image?
    
    public var showImages: Bool
    init(title: String, leftDisplay: LeftDisplay = .none, rightDisplay: RightDisplay = .none, image: SwiftUI.Image? = nil, showImages: Bool = false) {
        self.title = title
        self.leftDisplay = leftDisplay
        self.rightDisplay = rightDisplay
        self.image = image
        self.showImages = showImages
    }
}
