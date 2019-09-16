//
//  ScanConfirmationView.swift
//
//  Copyright © 2019 snabble. All rights reserved.
//

import UIKit

protocol ScanConfirmationViewDelegate: AnalyticsDelegate {
    func closeConfirmation(_ item: CartItem?)
}

final class ScanConfirmationView: DesignableView {
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var productNameLabel: UILabel!
    @IBOutlet private weak var originalPriceLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!

    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var quantityField: UITextField!
    @IBOutlet private weak var minusButton: UIButton!
    @IBOutlet private weak var plusButton: UIButton!
    @IBOutlet private weak var gramLabel: UILabel!

    @IBOutlet private weak var closeButton: UIButton!
    @IBOutlet private weak var cartButton: UIButton!

    weak var delegate: ScanConfirmationViewDelegate!

    private var alreadyInCart = false

    private weak var shoppingCart: ShoppingCart!
    private var cartItem: CartItem!

    override var isFirstResponder: Bool {
        return self.quantityField.isFirstResponder
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.view.backgroundColor = .clear
        self.addCornersAndShadow(backgroundColor: .white, cornerRadius: 8)

        self.cartButton.makeSnabbleButton()

        self.priceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .regular)

        self.minusButton.makeBorderedButton()
        self.plusButton.makeBorderedButton()

        self.quantityField.font = UIFont.monospacedDigitSystemFont(ofSize: 21, weight: .regular)
        self.quantityField.tintColor = SnabbleUI.appearance.primaryColor
        self.quantityField.delegate = self
        self.quantityField.addDoneButton()

        self.closeButton.setImage(UIImage.fromBundle("icon-close"), for: .normal)
        self.plusButton.setImage(UIImage.fromBundle("icon-plus"), for: .normal)
        self.minusButton.setImage(UIImage.fromBundle("icon-minus"), for: .normal)
    }

    func setCustomAppearance(_ appearance: CustomAppearance) {
        self.cartButton.setCustomAppearance(appearance)
    }
    
    func present(_ scannedProduct: ScannedProduct, _ scannedCode: String, cart: ShoppingCart) {
        // avoid ugly animations
        UIView.performWithoutAnimation {
            self.doPresent(scannedProduct, scannedCode, cart: cart)
            self.layoutIfNeeded()
        }
    }

    private func doPresent(_ scannedProduct: ScannedProduct, _ scannedCode: String, cart: ShoppingCart) {
        self.shoppingCart = cart
        self.alreadyInCart = false

        let product = scannedProduct.product
        self.productNameLabel.text = product.name

        let scannedCode = ScannedCode(
            scannedCode: scannedCode,
            transmissionCode: scannedProduct.transmissionCode,
            embeddedData: scannedProduct.embeddedData,
            encodingUnit: scannedProduct.encodingUnit,
            priceOverride: scannedProduct.priceOverride,
            referencePriceOverride: scannedProduct.referencePriceOverride,
            templateId: scannedProduct.templateId ?? "default",
            lookupCode: scannedProduct.lookupCode)

        self.cartItem = CartItem(1, product, scannedCode, cart.customerCard, SnabbleUI.project.roundingMode)

        let cartQuantity = self.shoppingCart.quantity(of: cartItem)
        self.alreadyInCart = cartQuantity > 0

        var quantity = cartQuantity + 1
        if product.type == .userMustWeigh {
            quantity = 0
        }

        if let embed = cartItem.scannedCode.embeddedData, product.referenceUnit?.hasDimension == true {
            quantity = embed
        }
        self.cartItem.quantity = quantity

        self.priceLabel.isHidden = false

        self.minusButton.isHidden = !self.cartItem.editable
        self.plusButton.isHidden = !self.cartItem.editable

        self.gramLabel.text = cartItem.encodingUnit?.display
        self.gramLabel.isHidden = !self.cartItem.editable

        self.quantityField.isHidden = !self.cartItem.editable

        self.subtitleLabel.text = product.subtitle

        if product.type == .userMustWeigh {
            self.quantityField.becomeFirstResponder()
        }

        self.showQuantity(updateTextField: true)

        let cartTitle = self.alreadyInCart ? "Snabble.Scanner.updateCart" : "Snabble.Scanner.addToCart"
        self.cartButton.setTitle(cartTitle.localized(), for: .normal)

        if product.discountedPrice != nil {
            let formatter = PriceFormatter(SnabbleUI.project)
            let originalPrice = formatter.format(product.listPrice)
            let str = NSAttributedString(string: originalPrice, attributes: [NSAttributedString.Key.strikethroughStyle: NSUnderlineStyle.single.rawValue])
            self.originalPriceLabel.attributedText = str
        } else {
            self.originalPriceLabel.text = nil
        }

        // suppress display when price == 0
        var hasPrice = product.price(cart.customerCard) != 0
        if self.cartItem.encodingUnit == .price {
            hasPrice = true
        }
        if !hasPrice {
            self.priceLabel.isHidden = true
            self.plusButton.isHidden = true
            self.minusButton.isHidden = true
            self.quantityField.isEnabled = false
        }
    }
    
    private func showQuantity(updateTextField: Bool) {
        var quantity = self.cartItem.effectiveQuantity
        let product = self.cartItem.product
        if quantity < 1 && product.type != .userMustWeigh {
            quantity = 1
        } else if quantity > ShoppingCart.maxAmount {
            quantity = ShoppingCart.maxAmount
        }

        if updateTextField {
            self.quantityField.text = quantity == 0 ? "" : "\(quantity)"
        }

        self.cartButton.isEnabled = quantity > 0
        self.minusButton.isEnabled = quantity > 1
        self.plusButton.isEnabled = quantity < ShoppingCart.maxAmount

        self.quantityField.isEnabled = self.cartItem.editable

        let formatter = PriceFormatter(SnabbleUI.project)
        let formattedPrice = self.cartItem.priceDisplay(formatter)
        let quantityDisplay = self.cartItem.quantityDisplay()

        let showQuantity = quantity != 1 || self.cartItem.product.deposit != nil
        self.priceLabel.text = (showQuantity ? quantityDisplay + " " : "") + formattedPrice
    }

    @IBAction private func plusTapped(_ button: UIButton) {
        self.cartItem.quantity += 1
        self.showQuantity(updateTextField: true)
    }

    @IBAction private func minusTapped(_ button: UIButton) {
        self.cartItem.quantity -= 1
        self.showQuantity(updateTextField: true)
    }

    @IBAction private func cartTapped(_ button: UIButton) {
        let cart = self.shoppingCart!

        if cart.quantity(of: self.cartItem) == 0 || !self.cartItem.canMerge {
            Log.info("adding to cart: \(self.cartItem.quantity) x \(self.cartItem.product.name), scannedCode = \(self.cartItem.scannedCode.code), embed=\(String(describing: self.cartItem.scannedCode.embeddedData))")
            cart.add(self.cartItem)
        } else {
            Log.info("updating cart: set qty=\(self.cartItem.quantity) for \(self.cartItem.product.name)")
            cart.setQuantity(self.cartItem.quantity, for: self.cartItem)
        }

        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        self.delegate.track(.productAddedToCart(self.cartItem.product.sku))
        self.delegate.closeConfirmation(self.cartItem)

        self.quantityField.resignFirstResponder()
    }

    @IBAction private func closeButtonTapped(_ button: UIButton) {
        self.delegate.track(.scanAborted(self.cartItem.product.sku))
        self.delegate.closeConfirmation(nil)
        self.quantityField.resignFirstResponder()
    }

}

extension ScanConfirmationView: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text as NSString? else {
            return false
        }

        let newText = text.replacingCharacters(in: range, with: string)
        let qty = Int(newText) ?? 0

        if qty < 0 || qty > ShoppingCart.maxAmount || (range.location == 0 && string == "0") {
            return false
        }

        self.cartItem.quantity = qty
        self.showQuantity(updateTextField: false)

        return true
    }

}
