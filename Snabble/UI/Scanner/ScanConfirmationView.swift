//
//  ScanConfirmationView.swift
//
//  Copyright © 2018 snabble. All rights reserved.
//

import UIKit

protocol ScanConfirmationViewDelegate: AnalyticsDelegate {
    func closeConfirmation()
}

public extension Notification.Name {
    static let snabbleCartUpdated = Notification.Name("snabbleCartUpdated")
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

    private var product: Product!
    private var alreadyInCart = false
    private var quantity = 1
    private var ean: EANCode?
    private var code = ""
    
    private weak var shoppingCart: ShoppingCart!

    override var isFirstResponder: Bool {
        return self.quantityField.isFirstResponder
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.view.backgroundColor = .clear
        self.addCornersAndShadow(backgroundColor: .white, cornerRadius: 8)

        self.cartButton.backgroundColor = SnabbleUI.appearance.primaryColor
        self.cartButton.tintColor = SnabbleUI.appearance.secondaryColor
        self.cartButton.makeRoundedButton()

        let mono14 = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        self.priceLabel.font = mono14

        self.minusButton.makeBorderedButton()
        self.plusButton.makeBorderedButton()

        self.quantityField.font = UIFont.monospacedDigitSystemFont(ofSize: 21, weight: .regular)
        self.quantityField.tintColor = SnabbleUI.appearance.primaryColor
        self.quantityField.delegate = self

        self.closeButton.setImage(UIImage.fromBundle("icon-close"), for: .normal)
        self.plusButton.setImage(UIImage.fromBundle("icon-plus"), for: .normal)
        self.minusButton.setImage(UIImage.fromBundle("icon-minus"), for: .normal)

        self.addDoneButton()
    }
    
    func present(_ product: Product, cart: ShoppingCart, code: String) {
        // avoid ugly animations
        UIView.performWithoutAnimation {
            self.doPresent(product, cart: cart, code: code)
            self.layoutIfNeeded()
        }
    }

    private func doPresent(_ product: Product, cart: ShoppingCart, code: String) {
        self.product = product
        self.productNameLabel.text = product.name
        self.shoppingCart = cart
        self.code = code
        self.ean = EAN.parse(code, SnabbleUI.project)
        self.alreadyInCart = false
        
        self.quantity = product.type != .userMustWeigh ? 1 : 0

        if product.type == .singleItem && self.ean?.hasEmbeddedData == false {
            let cartQuantity = self.shoppingCart.quantity(of: product)
            self.quantity = cartQuantity + 1
            self.alreadyInCart = cartQuantity > 0
        }

        let initialQuantity = ean?.embeddedWeight ?? self.quantity

        self.minusButton.isHidden = ean?.hasEmbeddedData == true
        self.plusButton.isHidden = ean?.hasEmbeddedData == true
        self.gramLabel.isHidden = !product.weightDependent
        self.quantityField.isEnabled = product.type != .preWeighed
        self.quantityField.isHidden = false

        self.subtitleLabel.text = product.subtitle

        if product.type == .userMustWeigh {
            self.quantityField.becomeFirstResponder()
        }

        self.showQuantity(initialQuantity, updateTextField: true)

        let cartTitle = self.alreadyInCart ? "Snabble.Scanner.updateCart" : "Snabble.Scanner.addToCart"
        self.cartButton.setTitle(cartTitle.localized(), for: .normal)

        if product.discountedPrice != nil {
            let originalPrice = PriceFormatter.format(product.listPrice)
            let str = NSAttributedString(string: originalPrice, attributes: [NSAttributedString.Key.strikethroughStyle: NSUnderlineStyle.single.rawValue])
            self.originalPriceLabel.attributedText = str
        } else {
            self.originalPriceLabel.text = nil
        }
    }
    
    private func showQuantity(_ quantity: Int, updateTextField: Bool) {
        var qty = quantity
        if quantity < 1 && self.product.type != .userMustWeigh {
            qty = 1
        } else if self.quantity > ShoppingCart.maxAmount {
            qty = ShoppingCart.maxAmount
        }

        if updateTextField {
            self.quantityField.text = qty == 0 ? "" : "\(qty)"
        }

        self.cartButton.isEnabled = qty > 0
        self.minusButton.isEnabled = qty > 1
        self.plusButton.isEnabled = qty < ShoppingCart.maxAmount

        if let weight = self.ean?.embeddedWeight {
            let productPrice = PriceFormatter.priceFor(self.product, weight)
            let priceKilo = PriceFormatter.format(product.price)
            let formattedPrice = PriceFormatter.format(productPrice)
            self.priceLabel.text = "\(qty)g × \(priceKilo)/kg = \(formattedPrice)"
        } else if let price = self.ean?.embeddedPrice {
            self.priceLabel.text = PriceFormatter.format(price)
            self.quantityField.isHidden = true
            self.gramLabel.isHidden = true
        } else if let amount = self.ean?.embeddedUnits {
            let productPrice = PriceFormatter.format(product.priceWithDeposit)
            let multiplier = amount == 0 ? self.quantity : amount
            let totalPrice = PriceFormatter.format(self.product.priceWithDeposit * multiplier)
            self.priceLabel.text = "\(multiplier) × \(productPrice) = \(totalPrice)"
            self.quantityField.isHidden = true
            self.gramLabel.isHidden = true
            self.minusButton.isHidden = amount > 0
            self.plusButton.isHidden = amount > 0
            self.quantityField.isHidden = amount > 0
        } else if product.type == .userMustWeigh {
            let productPrice = PriceFormatter.priceFor(self.product, quantity)
            let priceKilo = PriceFormatter.format(product.price)
            let formattedPrice = PriceFormatter.format(productPrice)
            self.priceLabel.text = "\(qty)g × \(priceKilo)/kg = \(formattedPrice)"
        } else {
            if let deposit = self.product.deposit {
                let productPrice = PriceFormatter.format(self.product.price)
                let depositPrice = PriceFormatter.format(deposit * qty)
                let totalPrice = PriceFormatter.format(PriceFormatter.priceFor(self.product, qty))
                let deposit = String(format: "Snabble.Scanner.plusDeposit".localized(), depositPrice)
                self.priceLabel.text = "\(qty) × \(productPrice) \(deposit) = \(totalPrice)"
            } else {
                let productPrice = PriceFormatter.priceFor(self.product, qty)
                self.priceLabel.text = PriceFormatter.format(productPrice)
            }
        }
    }

    private func addDoneButton() {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(UITextField.endEditing(_:)))
        keyboardToolbar.items = [ flexSpace, doneButton ]
        self.quantityField.inputAccessoryView = keyboardToolbar
    }

    @IBAction private func plusTapped(_ button: UIButton) {
        self.quantity += 1
        self.showQuantity(self.quantity, updateTextField: true)
    }

    @IBAction private func minusTapped(_ button: UIButton) {
        self.quantity -= 1
        self.showQuantity(self.quantity, updateTextField: true)
    }

    @IBAction private func cartTapped(_ button: UIButton) {
        let cart = self.shoppingCart!
        if cart.quantity(of: self.product) == 0 || self.product.type != .singleItem || self.ean?.hasEmbeddedData == true {
            var code = self.code
            var editableUnits = false
            // embedded units==0 (e.g. billa bakery shelf code)? generate new EAN from user-entered quantity
            if let ean = self.ean, ean.hasEmbeddedUnits, ean.embeddedUnits == 0 {
                code = EAN13.embedDataInEan(code, data: self.quantity)
                self.quantity = 1
                editableUnits = true
            }
            // Log.info("adding to cart: \(self.quantity) x \(self.product.name), code=\(code)")

            let ean = EAN.parse(code, SnabbleUI.project)
            cart.add(self.product, quantity: self.quantity, scannedCode: code, ean: ean, editableUnits: editableUnits)
        } else {
            // Log.info("updating cart: add \(self.quantity) to \(self.product.name)")
            cart.setQuantity(self.quantity, for: self.product)
        }

        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        self.delegate.closeConfirmation()

        self.quantityField.resignFirstResponder()
    }

    @IBAction private func closeButtonTapped(_ button: UIButton) {
        self.delegate.track(.scanAborted(self.product.sku))
        self.delegate.closeConfirmation()
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

        if qty > ShoppingCart.maxAmount || (range.location == 0 && string == "0") {
            return false
        }

        self.quantity = qty
        self.showQuantity(qty, updateTextField: false)

        return true
    }

}
