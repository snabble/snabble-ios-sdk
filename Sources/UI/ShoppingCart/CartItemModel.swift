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
    
    @Published public var cartItem: CartItem?
    
    public var itemName: String {
        guard let cartItem = self.cartItem else {
            return ""
        }
        return cartItem.product.name
    }
    
    public var itemQuantity: Int {
        guard let cartItem = self.cartItem else {
            return 0
        }
        let product = cartItem.product
        var quantity = cartItem.effectiveQuantity

        if quantity < 1 && product.type != .userMustWeigh {
            quantity = 1
        } else if quantity > ShoppingCart.maxAmount {
            quantity = ShoppingCart.maxAmount
        }
        return quantity
    }
    
    public var itemQuantityString: String {
        guard let cartItem = self.cartItem else {
            return ""
        }
        return cartItem.quantityDisplay()
    }
    
    public var hasPrice: Bool {
        guard let cartItem = self.cartItem,
              let product = scannedProduct?.product else {
            return false
        }

        // suppress display when price == 0
        var hasPrice = product.price(self.shoppingCart.customerCard) != 0
        if cartItem.encodingUnit == .price {
            hasPrice = true
        }
        return hasPrice
    }
    
    public var itemPrice: String {
        guard let cartItem = self.cartItem else {
            return ""
        }
        let showQuantity = itemQuantity != 1 || cartItem.product.deposit != nil
        return (showQuantity ? itemQuantityString + " " : "") + cartItem.priceDisplay(PriceFormatter(SnabbleCI.project))
    }
    
    public var shop: Shop
    public var shoppingCart: ShoppingCart
    public var scannedProduct: ScannedProduct? {
        didSet {
            if scannedProduct != nil {
                setupItem()
            }
        }
    }
    public var alreadyInCart = false
    
    private var cancellables = Set<AnyCancellable>()

    func setupItem() {
        guard let scannedProduct = self.scannedProduct,
              let code = scannedProduct.product.codes.first?.code else {
            return
        }
        
        let project = SnabbleCI.project
        let product = scannedProduct.product

        var embeddedData = scannedProduct.embeddedData
        if let embed = embeddedData, product.type == .depositReturnVoucher, scannedProduct.encodingUnit == .price {
            embeddedData = -1 * embed
        }

        let scannedCode = ScannedCode(
            scannedCode: code,
            transmissionCode: scannedProduct.transmissionCode,
            embeddedData: embeddedData,
            encodingUnit: scannedProduct.encodingUnit,
            priceOverride: scannedProduct.priceOverride,
            referencePriceOverride: scannedProduct.referencePriceOverride,
            templateId: scannedProduct.templateId ?? CodeTemplate.defaultName,
            transmissionTemplateId: scannedProduct.transmissionTemplateId,
            lookupCode: scannedProduct.lookupCode)

        self.cartItem = CartItem(1, scannedProduct.product, scannedCode, self.shoppingCart.customerCard, project.roundingMode)
        
        guard let cartItem = self.cartItem else {
            return
        }
        let cartQuantity = cartItem.canMerge ? self.shoppingCart.quantity(of: cartItem) : 0
        alreadyInCart = cartQuantity > 0

        let initialQuantity = scannedProduct.specifiedQuantity ?? 1
        var quantity = cartQuantity + initialQuantity
        if product.type == .userMustWeigh {
            quantity = 0
        }

        if let embed = cartItem.scannedCode.embeddedData, product.referenceUnit?.hasDimension == true {
            quantity = embed
        }
        self.cartItem?.setQuantity(quantity)

    }
    
    public init(productModel: ProductModel, product: Product) {
        
        self.shop = productModel.shop
        self.shoppingCart = Snabble.shared.shoppingCartManager.shoppingCart(for: shop)
        
        productModel.scannedProductPublisher
            .sink { [weak self] product in
                self?.scannedProduct = product
            }
            .store(in: &cancellables)
        
        _ = productModel.scannedProduct(for: product)
    }
    
    public func quantityIncrement() {
        guard let cartItem = self.cartItem else {
            return
        }
        let quantity = cartItem.quantity
        self.cartItem?.setQuantity(quantity + 1)
    }
    
    public func quantityDecrement() {
        guard let cartItem = self.cartItem else {
            return
        }
        let quantity = cartItem.quantity
        if quantity > 1 {
            self.cartItem?.setQuantity(quantity - 1)
        }
    }
    
    public func addToCart() {
        guard let cartItem = self.cartItem else {
            return
        }
        
        let cartQuantity = self.shoppingCart.quantity(of: cartItem)
        if cartQuantity == 0 || !cartItem.canMerge {
            Log.info("adding to cart: \(cartItem.quantity) x \(cartItem.product.name), scannedCode = \(cartItem.scannedCode.code), embed=\(String(describing: cartItem.scannedCode.embeddedData))")
            self.shoppingCart.add(cartItem)
        } else {
            Log.info("updating cart: set qty=\(cartItem.quantity) for \(cartItem.product.name)")
            self.shoppingCart.setQuantity(cartItem.quantity, for: cartItem)
        }
    }
}
