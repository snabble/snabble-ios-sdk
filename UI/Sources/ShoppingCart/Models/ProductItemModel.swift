//
//  ProductItemModel.swift
//  
//
//  Created by Uwe Tilemann on 23.03.23.
//

import Foundation
import Combine
import SnabbleCore
import SwiftUI
import SnabbleAssetProviding

open class ProductItemModel: CartItemModel, ShoppingCartItemCounting {
    public override var id: String {
        return item.uuid
    }
    let item: CartItem
    let lineItems: [CheckoutInfo.LineItem]
    
    @Published public var discounts: [ShoppingCartItemDiscount]
    @Published public var quantity: Int
    
    init(item: CartItem, for lineItems: [CheckoutInfo.LineItem], discounts: [ShoppingCartItemDiscount] = [], showImages: Bool = true) {
        self.item = item
        self.lineItems = lineItems
        self.discounts = discounts
        
        let defaultItem = lineItems.first { $0.type == .default }
        
        let product = item.product

        self.quantity = defaultItem?.quantity(for: product) ?? item.quantity

        super.init(title: defaultItem?.name ?? product.name, showImages: showImages)
        
        if item.editable {
            self.rightDisplay = .buttons
        } else if product.type == .preWeighed {
            self.rightDisplay = .weightDisplay
        }
        
        self.loadImage()
    }
}

extension ProductItemModel {
    var showWeight: Bool {
        return item.product.referenceUnit?.hasDimension == true
    }
    var showQuantity: Bool {
        return item.product.type == .singleItem || showWeight
    }
    var encodingUnit: Units? {
        return item.encodingUnit ?? item.product.encodingUnit
    }
    
    var quantityText: String? {
        return showQuantity ? "\(item.effectiveQuantity)" : nil
    }

    var unitString: String? {
        return showWeight ? encodingUnit?.display : nil
    }
}

extension ProductItemModel: ShoppingCartItemPricing {
    public var formatter: PriceFormatter {
        PriceFormatter(SnabbleCI.project)
    }
    
    var couponText: String {
        let coupons = lineItems.filter { $0.type == .coupon }
        return coupons.reduce("", { $0 + ($1.redeemed == true ? $1.name ?? "" : "") })
    }
    var discountText: String {
        let discounts = lineItems.filter { $0.type == .discount }
        return discounts.reduce("", { $0 + ($1.name ?? "") })
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
        let depositName = Asset.localizedString(forKey: "Snabble.Shoppingcart.deposit")
        
        return formatter.format(regularPrice - deposit) + " + " + formatter.format(deposit) + " " + depositName
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

extension ProductItemModel: ShoppingCartItemBadging {
        
    public var badgeText: String? {
        var badgeText: String?

        let saleRestricton = item.product.saleRestriction
        switch saleRestricton {
        case .none: ()
        case .age(let age): badgeText = "\(age)"
        case .fsk: badgeText = "FSK"
        }
        return badgeText
    }
}

extension ProductItemModel {
    private static var imageCache = [String: SwiftUI.Image]()

    private func loadImage() {
        guard
            let imgUrl = self.item.product.imageUrl,
            var url = URL(string: imgUrl)
        else {
            if self.showImages {
                self.leftDisplay = .emptyImage
            }
            return
        }

        self.leftDisplay = .image

        if let img = ProductItemModel.imageCache[imgUrl] {
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
                ProductItemModel.imageCache[imgUrl] = image
                DispatchQueue.main.async {
                    self?.image = image
                }
            }
        }
        task.resume()
    }
}
