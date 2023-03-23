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

public protocol ShoppingCartItemPricing {
    var regularPrice: Int { get }
    var discount: Int { get }
    var discountName: String? { get }
    var formatter: PriceFormatter { get }
}

public extension ShoppingCartItemPricing {
    var hasDiscount: Bool {
        return discount != 0
    }
    var discountedPrice: Int {
        guard hasDiscount else {
            return regularPrice
        }
        return regularPrice + discount
    }

    var discountPercent: Int {
        guard hasDiscount else { return 0 }
        return Int(100.0 - 100.0 / Double(regularPrice) * Double(discountedPrice))
    }
}

public extension ShoppingCartItemPricing {
    
    var discountAndPercentString: String {
        return formatter.format(discount) + " ≙ \(discountPercentString)"
    }
    var discountString: String {
        return formatter.format(discount)
    }

    var discountedPriceString: String {
        return formatter.format(discountedPrice)
    }

    var discountPercentString: String {
        return "-\(discountPercent)%"
    }
    var regularPriceString: String {
        guard self.regularPrice != 0 else {
            return ""
        }
        return formatter.format(regularPrice)
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
