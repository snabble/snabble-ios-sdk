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

    private var scannedProduct: ScannedProduct!
    private var alreadyInCart = false
    private var quantity = 1

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
    
    func present(_ scannedProduct: ScannedProduct, cart: ShoppingCart) {
        // avoid ugly animations
        UIView.performWithoutAnimation {
            self.doPresent(scannedProduct, cart: cart)
            self.layoutIfNeeded()
        }
    }

    private func doPresent(_ scannedProduct: ScannedProduct, cart: ShoppingCart) {
        self.scannedProduct = scannedProduct
        self.shoppingCart = cart
        self.alreadyInCart = false

        let product = scannedProduct.product
        self.productNameLabel.text = product.name
        self.quantity = product.type != .userMustWeigh ? 1 : 0

        if product.type == .singleItem && scannedProduct.embeddedData == nil {
            let cartQuantity = self.shoppingCart.quantity(of: product)
            self.quantity = cartQuantity + 1
            self.alreadyInCart = cartQuantity > 0
        }

        var initialQuantity = self.quantity // ean?.embeddedWeight ?? self.quantity
        if let embed = scannedProduct.embeddedData, product.referenceUnit?.hasUnit == true {
            initialQuantity = embed
        }

        self.minusButton.isHidden = scannedProduct.embeddedData != nil
        self.plusButton.isHidden = scannedProduct.embeddedData != nil

        self.gramLabel.text = product.encodingUnit?.display
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
        let product = self.scannedProduct.product
        if quantity < 1 && product.type != .userMustWeigh {
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

        let encodingSymbol = product.encodingUnit?.display ?? ""
        let referenceSymbol = product.referenceUnit?.display ?? ""

        if let weight = self.scannedProduct.embeddedData, product.referenceUnit?.hasUnit == true {
            let productPrice = PriceFormatter.priceFor(product, weight)
            let priceKilo = PriceFormatter.format(product.price)
            let formattedPrice = PriceFormatter.format(productPrice)
            self.priceLabel.text = "\(qty)\(encodingSymbol) × \(priceKilo)/\(referenceSymbol) = \(formattedPrice)"
        } else if let price = self.scannedProduct.embeddedData, product.referenceUnit == .price {
            self.priceLabel.text = PriceFormatter.format(price)
            self.quantityField.isHidden = true
            self.gramLabel.isHidden = true
        } else if let amount = self.scannedProduct.embeddedData, product.referenceUnit == .piece {
            let productPrice = PriceFormatter.format(product.priceWithDeposit)
            let multiplier = amount == 0 ? self.quantity : amount
            let totalPrice = PriceFormatter.format(product.priceWithDeposit * multiplier)
            self.priceLabel.text = "\(multiplier) × \(productPrice) = \(totalPrice)"
            self.quantityField.isHidden = true
            self.gramLabel.isHidden = true
            self.minusButton.isHidden = amount > 0
            self.plusButton.isHidden = amount > 0
            self.quantityField.isHidden = amount > 0
        } else if product.type == .userMustWeigh {
            let productPrice = PriceFormatter.priceFor(product, quantity)
            let priceKilo = PriceFormatter.format(product.price)
            let formattedPrice = PriceFormatter.format(productPrice)
            self.priceLabel.text = "\(qty)\(encodingSymbol) × \(priceKilo)/\(referenceSymbol) = \(formattedPrice)"
        } else {
            if let deposit = product.deposit {
                let productPrice = PriceFormatter.format(product.price)
                let depositPrice = PriceFormatter.format(deposit * qty)
                let totalPrice = PriceFormatter.format(PriceFormatter.priceFor(product, qty))
                let deposit = String(format: "Snabble.Scanner.plusDeposit".localized(), depositPrice)
                self.priceLabel.text = "\(qty) × \(productPrice) \(deposit) = \(totalPrice)"
            } else {
                let productPrice = PriceFormatter.priceFor(product, qty)
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
        let product = self.scannedProduct.product

        if cart.quantity(of: product) == 0 || product.type != .singleItem || self.scannedProduct.embeddedData != nil {
            var editableUnits = false
            if product.referenceUnit?.hasUnit == true && self.scannedProduct.embeddedData == 0 {
                self.quantity = 1
                editableUnits = true
            }
            // Log.info("adding to cart: \(self.quantity) x \(product.name), scannedCode = \(String(describing: self.scannedProduct.code)), embed=\(String(describing: self.scannedProduct.embeddedData)) editableUnits=\(editableUnits)")
            cart.add(product, quantity: self.quantity, scannedCode: self.scannedProduct.code ?? "", embeddedData: self.scannedProduct.embeddedData, editableUnits: editableUnits)
        } else {
            // Log.info("updating cart: set qty=\(self.quantity) for \(product.name)")
            cart.setQuantity(self.quantity, for: product)
        }

        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        self.delegate.closeConfirmation()

        self.quantityField.resignFirstResponder()
    }

    @IBAction private func closeButtonTapped(_ button: UIButton) {
        self.delegate.track(.scanAborted(self.scannedProduct.product.sku))
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
