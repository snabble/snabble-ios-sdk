//
//  ScanConfirmationView.swift
//
//  Copyright © 2020 snabble. All rights reserved.
//

import UIKit
import Capable

protocol ScanConfirmationViewDelegate: AnalyticsDelegate {
    func closeConfirmation(_ item: CartItem?)
    func showMessage(_ message: ScanMessage)
    func showMessages(_ messages: [ScanMessage])
}

final class ScanConfirmationView: DesignableView {
    @IBOutlet private var subtitleLabel: UILabel!
    @IBOutlet private var productNameLabel: UILabel!
    @IBOutlet private var originalPriceLabel: UILabel!
    @IBOutlet private var priceLabel: UILabel!

    @IBOutlet private var stackView: UIStackView!
    @IBOutlet private var quantityField: UITextField!
    @IBOutlet private var minusButton: UIButton!
    @IBOutlet private var plusButton: UIButton!
    @IBOutlet private var gramLabel: UILabel!

    @IBOutlet private var manualDiscountButton: UIButton!
    @IBOutlet private var closeButton: UIButton!
    @IBOutlet private var cartButton: UIButton!

    weak var delegate: ScanConfirmationViewDelegate!

    private weak var shoppingCart: ShoppingCart!
    private var cartItem: CartItem!

    override var isFirstResponder: Bool {
        return self.quantityField.isFirstResponder
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        self.view.backgroundColor = .clear
        self.addCornersAndShadow(backgroundColor: .systemBackground, cornerRadius: 8)

        self.cartButton.makeSnabbleButton()

        self.priceLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 17, weight: .regular)

        self.minusButton.makeBorderedButton()
        self.plusButton.makeBorderedButton()

        self.quantityField.font = UIFont.monospacedDigitSystemFont(ofSize: 21, weight: .regular)
        self.quantityField.tintColor = .label
        self.quantityField.delegate = self
        self.quantityField.addDoneButton()

        self.closeButton.setImage(UIImage.fromBundle("SnabbleSDK/icon-close"), for: .normal)
        self.plusButton.setImage(UIImage.fromBundle("SnabbleSDK/icon-plus"), for: .normal)
        self.minusButton.setImage(UIImage.fromBundle("SnabbleSDK/icon-minus"), for: .normal)

        let contrastRatio = UIColor.getContrastRatio(forTextColor: SnabbleUI.appearance.accentColor,
                                                     onBackgroundColor: .systemBackground)
        let conformanceLevel = ConformanceLevel(contrastRatio: contrastRatio ?? 1, fontSize: 17, isBoldFont: false)

        if conformanceLevel == .AA || conformanceLevel == .AAA {
            self.manualDiscountButton.tintColor = SnabbleUI.appearance.accentColor
        } else {
            self.manualDiscountButton.tintColor = .label
        }
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

        let project = SnabbleUI.project
        self.manualDiscountButton.isHidden = project.manualCoupons.isEmpty
        self.manualDiscountButton.setTitle(L10n.Snabble.addDiscount, for: .normal)

        let product = scannedProduct.product
        self.productNameLabel.text = product.name

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

        self.cartItem = CartItem(1, product, scannedCode, cart.customerCard, project.roundingMode)

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

        let cartTitle = alreadyInCart ? L10n.Snabble.Scanner.updateCart : L10n.Snabble.Scanner.addToCart
        self.cartButton.setTitle(cartTitle, for: .normal)

        if product.discountedPrice != nil && product.discountedPrice != product.listPrice {
            let formatter = PriceFormatter(project)
            let originalPrice = formatter.format(product.listPrice)
            let str = NSAttributedString(string: originalPrice,
                                         attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue])
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

        self.cartButton.isEnabled = quantity > 0

        if quantity < 1 && product.type != .userMustWeigh {
            quantity = 1
        } else if quantity > ShoppingCart.maxAmount {
            quantity = ShoppingCart.maxAmount
        }

        if updateTextField {
            self.quantityField.text = quantity == 0 ? "" : "\(quantity)"
        }

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

    @IBAction private func manualDiscountTapped(_ sender: UIButton) {
        let project = SnabbleUI.project

        let title = L10n.Snabble.addDiscount
        let actionSheet = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: L10n.Snabble.noDiscount, style: .default) { _ in
            self.cartItem.manualCoupon = nil
            self.showQuantity(updateTextField: true)
            self.manualDiscountButton.setTitle(title, for: .normal)
        })

        for coupon in project.manualCoupons {
            actionSheet.addAction(UIAlertAction(title: coupon.name, style: .default) { _ in
                let cartQuantity = self.shoppingCart.quantity(of: self.cartItem)
                if cartQuantity > 0 {
                    self.cartItem.quantity = 1
                }
                self.cartItem.manualCoupon = coupon
                self.showQuantity(updateTextField: true)
                self.manualDiscountButton.setTitle(coupon.name, for: .normal)
                self.cartButton.setTitle(L10n.Snabble.Scanner.addToCart, for: .normal)
            })
        }

        actionSheet.addAction(UIAlertAction(title: L10n.Snabble.cancel, style: .cancel, handler: nil))

        UIApplication.topViewController()?.present(actionSheet, animated: true)
    }

    @IBAction private func cartTapped(_ button: UIButton) {
        let cart = self.shoppingCart!

        let tapticFeedback = UINotificationFeedbackGenerator()
        tapticFeedback.notificationOccurred(.success)

        if self.cartItem.product.type == .depositReturnVoucher {
            // check if we already have this exact scanned code in the cart
            let index = cart.items.firstIndex(where: { $0.scannedCode.code == self.cartItem.scannedCode.code })
            if index != nil {
                let msg = ScanMessage(L10n.Snabble.Scanner.duplicateDepositScanned)
                self.delegate?.showMessage(msg)
                return
            }
        }

        let cartQuantity = cart.quantity(of: self.cartItem)
        if cartQuantity == 0 || !self.cartItem.canMerge {
            let item = self.cartItem!
            Log.info("adding to cart: \(item.quantity) x \(item.product.name), scannedCode = \(item.scannedCode.code), embed=\(String(describing: item.scannedCode.embeddedData))")
            cart.add(self.cartItem)
        } else {
            Log.info("updating cart: set qty=\(self.cartItem.quantity) for \(self.cartItem.product.name)")
            cart.setQuantity(self.cartItem.quantity, for: self.cartItem)
        }

        NotificationCenter.default.post(name: .snabbleCartUpdated, object: self)
        self.delegate.track(.productAddedToCart(self.cartItem.product.sku))

        self.productNameLabel.text = nil
        self.delegate.closeConfirmation(self.cartItem)

        self.quantityField.resignFirstResponder()

        let userInfo: [String: Any] = [
            "scannedCode": self.cartItem.scannedCode.code,
            "sku": self.cartItem.product.sku,
            "name": self.cartItem.product.name
        ]
        NotificationCenter.default.post(name: .snabbleHideScanConfirmation, object: nil, userInfo: userInfo)
    }

    @IBAction private func closeButtonTapped(_ button: UIButton) {
        self.delegate.track(.scanAborted(self.cartItem.product.sku))

        self.productNameLabel.text = nil
        self.delegate.closeConfirmation(nil)
        self.quantityField.resignFirstResponder()

        NotificationCenter.default.post(name: .snabbleHideScanConfirmation, object: nil)
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
