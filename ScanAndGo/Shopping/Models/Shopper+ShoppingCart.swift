//
//  ShoppingModel+ShoppingCart.swift
//  SnabbleScanAndGo
//
//  Created by Uwe Tilemann on 17.06.24.
//

import Foundation

import SnabbleCore
import SnabbleAssetProviding
import SnabbleUI

extension ShoppingCart {
    public func cartItem(for item: BarcodeManager.ScannedItem, project: Project) -> CartItem {
        let scannedProduct = item.scannedProduct
        let product = item.product
        
        let scannedCode = ScannedCode(
            scannedCode: item.code,
            transmissionCode: scannedProduct.transmissionCode,
            embeddedData: scannedProduct.embeddedData,
            encodingUnit: scannedProduct.encodingUnit,
            priceOverride: scannedProduct.priceOverride,
            referencePriceOverride: scannedProduct.referencePriceOverride,
            templateId: scannedProduct.templateId ?? CodeTemplate.defaultName,
            transmissionTemplateId: scannedProduct.transmissionTemplateId,
            lookupCode: scannedProduct.lookupCode)
        
        return CartItem(1, product, scannedCode, self.customerCard, project.roundingMode)
    }
}

extension Shopper {
    public func cartItem(for item: BarcodeManager.ScannedItem) -> (cartItem: CartItem, alreadyInCart: Bool) {
        let shoppingCart = barcodeManager.shoppingCart
        var cartItem = shoppingCart.cartItem(for: item, project: barcodeManager.project)
        
        let scannedProduct = item.scannedProduct
        let product = item.product
        
        let cartQuantity = cartItem.canMerge ? shoppingCart.quantity(of: cartItem) : 0
        let alreadyInCart = cartQuantity > 0
        
        let initialQuantity = scannedProduct.specifiedQuantity ?? 1
        var quantity = cartQuantity + initialQuantity
        
        if let embed = cartItem.scannedCode.embeddedData, product.referenceUnit?.hasDimension == true {
            quantity = embed
        }
        cartItem.setQuantity(quantity)
        
        return (cartItem, alreadyInCart)
    }
    
    public func updateCartItem(_ cartItem: CartItem) {
        let shop = barcodeManager.shop
        let shoppingCart = barcodeManager.shoppingCart
        
        let cartQuantity = shoppingCart.quantity(of: cartItem)
        if cartQuantity == 0 || !cartItem.canMerge {
            logger.info("adding to cart: \(cartItem.quantity) x \(cartItem.product.name), scannedCode = \(cartItem.scannedCode.code), embed=\(String(describing: cartItem.scannedCode.embeddedData))")
            shoppingCart.add(cartItem)
        } else {
            logger.info("updating cart: set qty=\(cartItem.quantity) for \(cartItem.product.name)")
            shoppingCart.setQuantity(cartItem.quantity, for: cartItem)
        }
        
        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        self.track(.productAddedToCart(cartItem.product.sku))
        
        if let location = Snabble.shared.checkInManager.locationManager.location {
            AppEvent(key: "Add to cart distance to shop", value: "\(shop.id.rawValue);\(shop.distance(to: location))m", project: barcodeManager.project, shopId: shop.id).post()
        }
    }
}

extension Shopper {
    public var numberOfItemsInCart: String {
        Asset.localizedString(forKey: "Snabble.Shoppingcart.numberOfItems", arguments: barcodeManager.shoppingCart.numberOfItems)
    }
    
    public var canCheckout: Bool {
        return barcodeManager.shoppingCart.numberOfItems > 0 && (totalPrice ?? 0) >= 0
    }
    
    public var totalPriceString: String {
        guard let total = totalPrice else {
            return ""
        }
        let formatter = PriceFormatter(barcodeManager.project)
        return formatter.format(total)
    }
    
    public var totalPrice: Int? {
        let backendCartInfo = barcodeManager.shoppingCart.backendCartInfo
        
        let nilPrice: Bool
        if let items = backendCartInfo?.lineItems {
            let productsNoPrice = items.filter { $0.type == .default && $0.totalPrice == nil }
            nilPrice = !productsNoPrice.isEmpty
        } else {
            nilPrice = false
        }
        
        let cartTotal = barcodeManager.project.displayNetPrice ? backendCartInfo?.netPrice : backendCartInfo?.totalPrice
        let totalPrice = nilPrice ? nil : (cartTotal ?? barcodeManager.shoppingCart.total)
        
        return totalPrice
    }
}
