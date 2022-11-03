//
//  CartItemModel.swift
//  
//
//  Created by Uwe Tilemann on 03.11.22.
//

import SnabbleCore
import Combine

// MARK: - Publisher object that emits published products

public final class CartItemModel: ObservableObject {
    
    @Published public var cartItem: CartItem
    
    public var itemQuantity: String {
        var quantity = self.cartItem.effectiveQuantity
        let product = self.cartItem.product

        if quantity < 1 && product.type != .userMustWeigh {
            quantity = 1
        } else if quantity > ShoppingCart.maxAmount {
            quantity = ShoppingCart.maxAmount
        }

        return quantity == 0 ? "" : "\(quantity)"
    }
    
    public var itemPrice: String {
        let product = scannedProduct.product
        
        if product.discountedPrice != nil && product.discountedPrice != product.listPrice {
            let formatter = PriceFormatter(SnabbleCI.project)
            return formatter.format(product.listPrice)
        } else {
            return ""
        }
    }
    
    public var shop: Shop
    public var shoppingCart: ShoppingCart
    public var scannedProduct: ScannedProduct
    
    public init(shop: Shop, scannedProduct: ScannedProduct, scannedCode: String) {
        let project = SnabbleCI.project
        
        self.shop = shop
        self.scannedProduct = scannedProduct
        
        self.shoppingCart = Snabble.shared.shoppingCartManager.shoppingCart(for: shop)
        
        let product = scannedProduct.product

        var embeddedData = scannedProduct.embeddedData
        if let embed = embeddedData, product.type == .depositReturnVoucher, scannedProduct.encodingUnit == .price {
            embeddedData = -1 * embed
        }

        let scannedCode = ScannedCode(
            scannedCode: scannedCode,
            transmissionCode: scannedProduct.transmissionCode,
            embeddedData: embeddedData,
            encodingUnit: scannedProduct.encodingUnit,
            priceOverride: scannedProduct.priceOverride,
            referencePriceOverride: scannedProduct.referencePriceOverride,
            templateId: scannedProduct.templateId ?? CodeTemplate.defaultName,
            transmissionTemplateId: scannedProduct.transmissionTemplateId,
            lookupCode: scannedProduct.lookupCode)


        self.cartItem = CartItem(1, self.scannedProduct.product, scannedCode, self.shoppingCart.customerCard, project.roundingMode)
        
        let cartQuantity = self.cartItem.canMerge ? self.shoppingCart.quantity(of: self.cartItem) : 0
        let alreadyInCart = cartQuantity > 0

        let initialQuantity = scannedProduct.specifiedQuantity ?? 1
        var quantity = cartQuantity + initialQuantity
        if product.type == .userMustWeigh {
            quantity = 0
        }

        if let embed = cartItem.scannedCode.embeddedData, product.referenceUnit?.hasDimension == true {
            quantity = embed
        }
        self.cartItem.setQuantity(quantity)
    }
    
    public func quantityIncrement() {
        let quantity = cartItem.quantity
        cartItem.setQuantity(quantity + 1)
    }
    
    public func quantityDecrement() {
        let quantity = cartItem.quantity
        if quantity > 1 {
            cartItem.setQuantity(quantity - 1)
        }
    }
}

