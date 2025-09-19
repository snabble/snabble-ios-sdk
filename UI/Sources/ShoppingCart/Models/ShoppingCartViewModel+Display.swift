//
//  File.swift
//  Snabble
//
//  Created by Uwe Tilemann on 19.09.25.
//

import Foundation

import SnabbleAssetProviding

// MARK: - Total Display Logic
extension ShoppingCartViewModel {

    var regularTotal: Int? {
        guard let total = shoppingCart.total else {
            return nil
        }
        return total
    }

    var regularTotalString: String {
        guard let regularTotal = regularTotal else {
            return ""
        }
        return formatter.format(regularTotal)
    }

    var total: Int? {
        let cartTotal = SnabbleCI.project.displayNetPrice ? shoppingCart.backendCartInfo?.netPrice : shoppingCart.backendCartInfo?.totalPrice

        return cartTotal ?? shoppingCart.total
    }

    var totalString: String {
        guard let total = total else {
            return ""
        }
        return formatter.format(total)
    }
}

// MARK: - CartEntry Display Logic
extension ShoppingCartViewModel {

    func regularPrice(for cartEntry: CartEntry) -> Int {
        guard case .cartItem(let item, let lineItems) = cartEntry else { return 0 }

        guard let defaultItem = lineItems.first(where: { $0.type == .default }), defaultItem.priceModifiers == nil else {
            return item.price
        }
        guard let deposit = depositTotal(for: cartEntry) else {
            return defaultItem.totalPrice ?? 0
        }
        return (defaultItem.totalPrice ?? 0) + deposit
    }

    func depositTotal(for cartEntry: CartEntry) -> Int? {
        guard case .cartItem(_, let lineItems) = cartEntry else { return nil }
        guard let depositTotal = lineItems.first(where: { $0.type == .deposit })?.totalPrice else {
            return nil
        }
        return depositTotal
    }

    func hasDeposit(for cartEntry: CartEntry) -> Bool {
        return depositTotal(for: cartEntry) != nil
    }

    func depositDetailString(for cartEntry: CartEntry) -> String? {
        guard let deposit = depositTotal(for: cartEntry) else {
            return nil
        }
        let depositName = Asset.localizedString(forKey: "Snabble.Shoppingcart.deposit")
        let regular = regularPrice(for: cartEntry)

        return formatter.format(regular - deposit) + " + " + formatter.format(deposit) + " " + depositName
    }

    func regularPriceString(for cartEntry: CartEntry) -> String {
        let regular = regularPrice(for: cartEntry)
        guard regular != 0 else {
            return ""
        }
        if hasDeposit(for: cartEntry) {
            let total = formatter.format(regular)
            let includesDeposit = Asset.localizedString(forKey: "Snabble.Shoppingcart.includesDeposit")
            return "\(total) \(includesDeposit)"
        }
        return formatter.format(regular)
    }

    func badgeText(for cartEntry: CartEntry) -> String? {
        guard case .cartItem(let item, _) = cartEntry else { return nil }

        let saleRestricton = item.product.saleRestriction
        switch saleRestricton {
        case .none: return nil
        case .age(let age): return "\(age)"
        case .fsk: return "FSK"
        }
    }

    func quantity(for cartEntry: CartEntry) -> Int {
        guard case .cartItem(let item, _) = cartEntry else { return 0 }
        return item.effectiveQuantity
    }

    func quantityText(for cartEntry: CartEntry) -> String? {
        guard case .cartItem(let item, _) = cartEntry else { return nil }
        let showQuantity = item.product.type == .singleItem || (item.product.referenceUnit?.hasDimension == true)
        return showQuantity ? "\(item.effectiveQuantity)" : nil
    }

    func unitString(for cartEntry: CartEntry) -> String? {
        guard case .cartItem(let item, _) = cartEntry else { return nil }
        let showWeight = item.product.referenceUnit?.hasDimension == true
        let encodingUnit = item.encodingUnit ?? item.product.encodingUnit
        return showWeight ? encodingUnit?.display : nil
    }

    func discounts(for cartEntry: CartEntry) -> [ShoppingCartItemDiscount] {
        guard case .cartItem(let item, let lineItems) = cartEntry else { return [] }
        return discountItems(item: item, for: lineItems)
    }

    func hasDiscount(for cartEntry: CartEntry) -> Bool {
        return !discounts(for: cartEntry).isEmpty
    }

    func reducedPriceString(for cartEntry: CartEntry) -> String {
        let regular = regularPrice(for: cartEntry)
        let discountItems = discounts(for: cartEntry)
        let totalDiscount = discountItems.reduce(0) { $0 + $1.discount }
        let reducedPrice = regular - totalDiscount
        return formatter.format(reducedPrice)
    }

    func rightDisplay(for cartEntry: CartEntry) -> CartItemModel.RightDisplay {
        guard case .cartItem(let item, _) = cartEntry else { return .none }

        if item.editable {
            return .buttons
        } else if item.product.type == .preWeighed {
            return .weightDisplay
        }
        return .none
    }

    func leftDisplay(for cartEntry: CartEntry) -> CartItemModel.LeftDisplay {
        guard case .cartItem(let item, _) = cartEntry else { return .none }

        if showImages, let imageUrl = item.product.imageUrl, !imageUrl.isEmpty {
            return .image
        } else if showImages {
            return .emptyImage
        }
        return .none
    }

    func title(for cartEntry: CartEntry) -> String {
        guard case .cartItem(let item, let lineItems) = cartEntry else { return "" }

        let defaultItem = lineItems.first { $0.type == .default }
        return defaultItem?.name ?? item.product.name
    }
}

