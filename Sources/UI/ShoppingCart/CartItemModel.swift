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
    var id: UUID { get }
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

open class CartItemModel: ObservableObject, ShoppingCartItem, ShoppingCartItemCounting {
    public let id = UUID()
    let item: CartItem
    let lineItems: [CheckoutInfo.LineItem]
    public var showImages: Bool
    
    @Published public var quantity: Int
    @Published public var title: String

    @Published public var leftDisplay: LeftDisplay = .none
    @Published public var rightDisplay: RightDisplay = .buttons
    @Published public var image: SwiftUI.Image?
    
    init(item: CartItem, for lineItems: [CheckoutInfo.LineItem], showImages: Bool = true) {
        self.item = item
        self.lineItems = lineItems
        
        let defaultItem = lineItems.first { $0.type == .default }

        self.quantity = defaultItem?.weight ?? defaultItem?.amount ?? item.quantity

        let product = item.product
        self.title = defaultItem?.name ?? product.name

        if item.editable {
            if product.type == .userMustWeigh {
                self.rightDisplay = .weightEntry
            } else {
                self.rightDisplay = .buttons
            }
        } else if product.type == .preWeighed {
            self.rightDisplay = .weightDisplay
        }
        self.showImages = showImages
        
        self.loadImage()
    }
}

extension CartItemModel: ShoppingCartItemPricing {

    public var formatter: PriceFormatter {
        PriceFormatter(SnabbleCI.project)
    }

    var priceModifier: (price: Int, text: String) {
        var modifiedPrice = 0
        var text = ""
        
        for lineItem in lineItems {
            guard let modifiers = lineItem.priceModifiers else { continue }
            let modSum = modifiers.reduce(0, { $0 + $1.price })
            let modText = modifiers.reduce("", { $0 + $1.name })
            modifiedPrice += modSum * lineItem.amount
            text += modText
        }
        return (modifiedPrice, text)
    }
    
    var couponText: String {
        let coupons = lineItems.filter { $0.type == .coupon }
        return coupons.reduce("", { $0 + ($1.name ?? "") })
    }
    var discountText: String {
        let discounts = lineItems.filter { $0.type == .discount }
        return discounts.reduce("", { $0 + ($1.name ?? "") })
    }
    
    public var discount: Int {
        let discounts = lineItems.filter { $0.type == .discount }
        let discount = discounts.reduce(0) { $0 + $1.amount * ($1.price ?? 0) }
        if discount != 0 {
            return discount
        }
        return priceModifier.price
    }

    public var discountName: String? {
        let name = priceModifier.text
        if !name.isEmpty {
            return name
        }
        let couponName = couponText
        if !couponName.isEmpty {
            return couponName
        }
        let discountText = discountText
        return discountText.isEmpty ? nil : discountText
    }
    
    public var regularPrice: Int {
        guard let defaultItem = lineItems.first(where: { $0.type == .default }), defaultItem.priceModifiers == nil else {
            return item.price
        }
        guard let deposit = depositTotal else {
            return defaultItem.totalPrice ?? 0
        }
        return (defaultItem.totalPrice ?? 0) + deposit
    }

    var depositTotal: Int? {
        guard let depositTotal = lineItems.first(where: { $0.type == .deposit })?.totalPrice else {
            return nil
        }
        return depositTotal
    }
    
    var hasDeposit: Bool {
        return depositTotal != nil
    }
    
    var depositDetailString: String? {
        guard let deposit = depositTotal else {
            return nil
        }
        let depositName = lineItems.first(where: { $0.type == .deposit })?.name
        
        return formatter.format(regularPrice - deposit) + " + " + formatter.format(deposit) + " " + (depositName ?? "")
    }
    
    var regularPriceString: String {
        guard self.regularPrice != 0 else {
            return ""
        }
        if hasDeposit {
            let total = formatter.format(regularPrice)
            let includesDeposit = Asset.localizedString(forKey: "Snabble.Shoppingcart.includesDeposit")
            return "\(total) \(includesDeposit)"
        }
        return formatter.format(regularPrice)
    }
}

extension CartItemModel {
    var badgeText: String? {
        var badgeText: String?
//        if item.manualCoupon != nil {
//            badgeText = "%"
//        }
        let saleRestricton = item.product.saleRestriction
        switch saleRestricton {
        case .none: ()
        case .age(let age): badgeText = "\(age)"
        case .fsk: badgeText = "FSK"
        }
        return badgeText
    }
}

extension CartItemModel {
    private static var imageCache = [String: SwiftUI.Image]()

    private func loadImage() {
        guard
            let imgUrl = self.item.product.imageUrl,
            var url = URL(string: imgUrl)
        else {
            // if self.showImages {
                self.leftDisplay = .emptyImage
            // }
            return
        }

        self.leftDisplay = .image

        if let img = CartItemModel.imageCache[imgUrl] {
            self.image = img
            return
        }
        // SDK Supermarket hack to resolve wrong domain in data
        if url.host == "snabble.io" {
            let path = url.path
            
            let newUrlString = (url.scheme ?? "https") + "://demodata.snabble.io" + path
            url = URL(string: newUrlString)!
        }
        let task = Snabble.urlSession.dataTask(with: url) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                return
            }

            if let uiImage = UIImage(data: data) {
                let image = SwiftUI.Image(uiImage: uiImage)
                CartItemModel.imageCache[imgUrl] = image
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
        }
        task.resume()
    }

}
